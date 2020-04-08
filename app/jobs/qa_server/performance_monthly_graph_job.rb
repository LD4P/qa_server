# frozen_string_literal: true
# Job to run monitoring tests
module QaServer
  class PerformanceMonthlyGraphJob < ApplicationJob
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
        auths = authority_list_class.authorities_list
        generate_graphs_for_authority(authority_name: ALL_AUTH) # generates graph for all authorities
        auths.each { |authname| generate_graphs_for_authority(authority_name: authname) }
      end

      def generate_graphs_for_authority(authority_name:)
        [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
          hash[action] = generate_12_month_graph(authority_name: authority_name, action: action)
        end
      end

      def generate_12_month_graph(authority_name:, action:)
        # real expiration or force caught by cache_expired?  So if we are here, either the cache has expired
        # or force was requested.  We still expire the cache and use ttl to catch race conditions.
        Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                          expires_in: next_expiry, race_condition_ttl: 1.hour, force: true) do
          data = graph_data_service.calculate_last_12_months(authority_name: authority_name, action: action)
          graphing_service.generate_monthly_graph(authority_name: authority_name, action: action, data: data)
          data
        end
      end

      def job_key
        "QaServer::PerformanceMonthlyGraphJob--job_id"
      end

      def cache_key_for_authority_action(authority_name:, action:)
        "QaServer::PerformanceMonthlyGraphJob--data--#{authority_name}--#{action}"
      end
  end
end
