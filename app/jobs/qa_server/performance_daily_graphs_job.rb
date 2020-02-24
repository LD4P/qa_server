# frozen_string_literal: true
# Job to generate daily performance graphs.
module QaServer
  class PerformanceDailyGraphsJob < ApplicationJob
    queue_as :default

    include QaServer::PerformanceHistoryDataKeys

    class_attribute :authority_list_class, :graph_data_service, :graphing_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.graph_data_service = QaServer::PerformanceGraphDataService
    self.graphing_service = QaServer::PerformanceGraphingService

    def perform
      job_id = SecureRandom.uuid
      graph_job_id = job_id unless graph_job_id
      generate_graphs(job_id) if graph_job_id == job_id # avoid race conditions
    end

    private

      def generate_graphs(job_id)
        QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}-#{job_id}) GENERATING DAILY performance graphs")
        generate_graphs_for_authorities
        reset_graph_job_id
        QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}-#{job_id}) COMPLETED DAILY performance graphs generation")
      end

      def generate_graphs_for_authorities
        auths = authority_list_class.authorities_list
        generate_graphs_for_authority(authority_name: ALL_AUTH) # generates graph for all authorities
        auths.each { |authname| generate_graphs_for_authority(authority_name: authname) }
      end

      def generate_graphs_for_authority(authority_name:)
        [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
          hash[action] = generate_30_day_graph(authority_name: authority_name, action: action)
        end
      end

      def generate_30_day_graph(authority_name:, action:)
        data = graph_data_service.calculate_last_30_days(authority_name: authority_name, action: action)
        graphing_service.generate_daily_graph(authority_name: authority_name, action: action, data: data)
      end

      # @return [String, Boolean] Returns job id of the job currently running tests; otherwise, false if tests are not running
      def graph_job_id
        Rails.cache.fetch("QaServer:performance_daily_graphs-job_id", expires_in: 2.hours, race_condition_ttl: 5.minutes) { false }
      end

      # Set the id of the job that will run the tests.
      # @param job_id [String] UUID for job running the tests
      def graph_job_id=(job_id)
        # check to see if there is a current job already running tests
        current_job_id = Rails.cache.fetch("QaServer:performance_daily_graphs-job_id", expires_in: 2.hours, race_condition_ttl: 5.seconds) { job_id }

        # current_job_id may be false meaning tests are not currently running; in which case, it is ok to force set job_id
        Rails.cache.fetch("QaServer:performance_daily_graphs-job_id", expires_in: 2.hours, race_condition_ttl: 30.seconds, force: true) { job_id } unless current_job_id
      end

      # Set job id for performance_daily_graphs to false indicating that tests are not currently running
      def reset_graph_job_id
        Rails.cache.fetch("QaServer:performance_daily_graphs-job_id", expires_in: 2.hours, race_condition_ttl: 30.seconds, force: true) { false }
      end
  end
end
