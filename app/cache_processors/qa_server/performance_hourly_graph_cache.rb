# frozen_string_literal: true
# Generate graphs for the past 24 hours using cached data.  The last hour of data is always calculated and all graphs
# for are generated.
module QaServer
  class PerformanceHourlyGraphCache
    class_attribute :authority_list_class, :graph_data_service, :graphing_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.graph_data_service = QaServer::PerformanceGraphDataService
    self.graphing_service = QaServer::PerformanceGraphingService

    class << self
      include QaServer::CacheKeys
      include QaServer::PerformanceHistoryDataKeys

      # Generates graphs for the past 24 hours for :search, :fetch, and :all actions for each authority.
      # @param force [Boolean] if true, run the tests even if the cache hasn't expired; otherwise, use cache if not expired
      def generate_graphs(force: false)
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceHourlyGraphCache) - GENERATING hourly performance graphs (force: #{force})")
        QaServer.config.performance_cache.write_all
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
            hash[action] = generate_24_hour_graph(authority_name: authority_name, action: action, force: force)
          end
        end

        def generate_24_hour_graph(authority_name:, action:, force:)
          graph_created = false
          data = Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                                   expires_in: QaServer::TimeService.current_time.end_of_hour - QaServer::TimeService.current_time,
                                   race_condition_ttl: 1.hour, force: force) do
            data = graph_data_service.calculate_last_24_hours(authority_name: authority_name, action: action)
            graphing_service.generate_hourly_graph(authority_name: authority_name, action: action, data: data)
            graph_created = true
            data
          end
          regen_last_hour_and_graph(authority_name: authority_name, action: action, data: data) unless graph_created
        end

        def regen_last_hour_and_graph(authority_name:, action:, data:)
          Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                            expires_in: QaServer::TimeService.current_time.end_of_hour - QaServer::TimeService.current_time,
                            race_condition_ttl: 1.hour, force: true) do
            data = graph_data_service.recalculate_last_hour(authority_name: authority_name, action: action, averages: data)
            graphing_service.generate_hourly_graph(authority_name: authority_name, action: action, data: data)
            data
          end
        end

        def cache_key_for_authority_action(authority_name:, action:)
          "#{PERFORMANCE_GRAPH_HOURLY_DATA_CACHE_KEY}--#{authority_name}--#{action}"
        end
    end
  end
end
