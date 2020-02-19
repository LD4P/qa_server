# frozen_string_literal: true
# Generate graphs for the past 30 days using cached data.  Graphs are generated only if the cache has expired.
module QaServer
  class PerformanceDailyGraphCache
    class_attribute :authority_list_class, :graph_data_service, :graphing_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.graph_data_service = QaServer::PerformanceGraphDataService
    self.graphing_service = QaServer::PerformanceGraphingService

    class << self
      include QaServer::PerformanceHistoryDataKeys

      # Generates graphs for the past 30 days for :search, :fetch, and :all actions for each authority.
      def generate_graphs(force: false)
        generate_graphs_for_authorities(force: force)
      end

      private

        def generate_graphs_for_authorities(force:)
          auths = authority_list_class.authorities_list
          generate_graphs_for_authority(authority_name: ALL_AUTH, force: force) # generates graph for all authorities
          auths.each { |authname| generate_graphs_for_authority(authority_name: authname, force: force) }
        end

        def generate_graphs_for_authority(authority_name:, force:)
          [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
            hash[action] = generate_30_day_graph(authority_name: authority_name, action: action, force: force)
          end
        end

        def generate_30_day_graph(authority_name:, action:, force:)
          Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                            expires_in: QaServer::CacheExpiryService.cache_expiry,
                            race_condition_ttl: 1.hour, force: force) do
            QaServer.config.monitor_logger.debug("(QaServer::PerformanceDailyGraphCache) - GENERATING daily performance graphs")
            data = graph_data_service.calculate_last_30_days(authority_name: authority_name, action: action)
            graphing_service.generate_daily_graph(authority_name: authority_name, action: action, data: data)
            data
          end
        end

        def cache_key_for_authority_action(authority_name:, action:)
          "#{QaServer::CacheKeys::PERFORMANCE_GRAPH_DAILY_DATA}-#{authority_name}-#{action}"
        end
    end
  end
end
