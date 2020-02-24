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
      # @param force [Boolean] if true, generate graphs even if the cache hasn't expired; otherwise, use cache if not expired
      def generate_graphs(force: false)
        # TODO: Since regenerate is not called if the cache expired, the graphs may display with stale data while the graphs
        #       are being fully regenerated.  Consider a way to regenerate the last hour in the current data that can be run
        #       while full graph regeneration is happening in the background.
        return regenerate_graphs_for_authorities unless QaServer::CacheExpiryService.cache_expired?(key: hourly_cache_key_for_force, force: force, next_expiry: next_expiry)
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceHourlyGraphCache) - KICKING OFF HOURLY GRAPHS GENERATION (force: #{force})")
        QaServer::PerformanceHourlyGraphsJob.perform_later
      end

      private

        def regenerate_graphs_for_authorities
          QaServer.config.monitor_logger.debug("(QaServer::PerformanceHourlyGraphCache) - RE-GENERATING HOURLY performance graphs")
          auths = authority_list_class.authorities_list
          generate_graphs_for_authority(authority_name: ALL_AUTH) # generates graph for all authorities
          auths.each { |authname| generate_graphs_for_authority(authority_name: authname) }
          QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}-#{job_id}) COMPLETED HOURLY performance graphs re-generation")
        end

        def generate_graphs_for_authority(authority_name:)
          [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
            hash[action] = generate_24_hour_graph(authority_name: authority_name, action: action)
          end
        end

        def generate_24_hour_graph(authority_name:, action:)
          data = Rails.cache.fetch(hourly_cache_key_for_authority_action(authority_name: authority_name, action: action))
          regen_last_hour_and_graph(authority_name: authority_name, action: action, data: data)
        end

        def regen_last_hour_and_graph(authority_name:, action:, data:)
          Rails.cache.fetch(hourly_cache_key_for_authority_action(authority_name: authority_name, action: action),
                            expires_in: next_expiry, race_condition_ttl: 1.hour, force: true) do
            data = graph_data_service.recalculate_last_hour(authority_name: authority_name, action: action, averages: data)
            graphing_service.generate_hourly_graph(authority_name: authority_name, action: action, data: data)
            data
          end
        end

        def hourly_cache_key_for_force
          cache_key_for_force(PERFORMANCE_GRAPH_HOURLY_DATA_CACHE_KEY)
        end

        def next_expiry
          QaServer::TimeService.current_time.end_of_hour - QaServer::TimeService.current_time
        end
    end
  end
end
