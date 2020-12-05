# frozen_string_literal: true
# Job to generate the performance month graph covering the last 30 days.
module QaServer
  class PerformanceMonthGraphJob < ApplicationJob
    include QaServer::PerformanceHistoryDataKeys

    queue_as :default

    class_attribute :authority_list_class, :graph_data_service, :graphing_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.graph_data_service = QaServer::PerformanceGraphDataService
    self.graphing_service = QaServer::PerformanceGraphingService

    def perform
      # checking active_job_id? prevents race conditions for long running jobs
      generate_graphs_for_authorities if QaServer::JobIdCache.active_job_id?(job_key: job_key, job_id: job_id)
    end

  private

    def generate_graphs_for_authorities
      QaServer.config.monitor_logger.debug("(#{self.class}-#{job_id}) - GENERATING performance month graph")
      auths = authority_list_class.authorities_list
      generate_graphs_for_authority(authority_name: ALL_AUTH) # generates graph for all authorities
      auths.each { |authname| generate_graphs_for_authority(authority_name: authname) }
      QaServer.config.monitor_logger.debug("(#{self.class}-#{job_id}) COMPLETED performance month graph generation")
      QaServer::JobIdCache.reset_job_id(job_key: job_key)
    end

    def generate_graphs_for_authority(authority_name:)
      [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
        hash[action] = generate_30_day_graph(authority_name: authority_name, action: action)
      end
    end

    def generate_30_day_graph(authority_name:, action:)
      data = graph_data_service.calculate_last_30_days(authority_name: authority_name, action: action)
      graphing_service.generate_month_graph(authority_name: authority_name, action: action, data: data)
    end

    def job_key
      "QaServer::PerformanceMonthGraphJob--job_id"
    end
  end
end
