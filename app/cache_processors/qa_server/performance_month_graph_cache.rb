# frozen_string_literal: true
# Generate graphs for the past 30 days using cached data.  Graphs are generated only if the cache has expired.
module QaServer
  class PerformanceMonthGraphCache
    class_attribute :authority_list_class, :graph_data_service, :graphing_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.graph_data_service = QaServer::PerformanceGraphDataService
    self.graphing_service = QaServer::PerformanceGraphingService

    class << self
      include QaServer::CacheKeys
      include QaServer::PerformanceHistoryDataKeys

      # Generates graphs for the past 30 days for :search, :fetch, and :all actions for each authority.
      # @param force [Boolean] if true, run the tests even if the cache hasn't expired; otherwise, use cache if not expired
      def generate_graphs(force: false)
        return unless QaServer::CacheExpiryService.cache_expired?(key: cache_key_for_force, force: force, next_expiry: next_expiry)
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceMonthGraphCache) - GENERATING performance month graphs (force: #{force})")
        generate_graphs_for_authorities
      end

      private

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
          # real expiration or force caught by cache_expired?  So if we are here, either the cache has expired
          # or force was requested.  We still expire the cache and use ttl to catch race conditions.
          Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                            expires_in: next_expiry, race_condition_ttl: 1.hour, force: true) do
            data = graph_data_service.calculate_last_30_days(authority_name: authority_name, action: action)
            graphing_service.generate_month_graph(authority_name: authority_name, action: action, data: data)
            data
          end
        end

        def cache_key_for_authority_action(authority_name:, action:)
          "#{PERFORMANCE_GRAPH_MONTH_DATA_CACHE_KEY}--#{authority_name}--#{action}"
        end

        def cache_key_for_force
          "#{PERFORMANCE_GRAPH_MONTH_DATA_CACHE_KEY}--force"
        end

        def next_expiry
          QaServer::CacheExpiryService.cache_expiry
        end
    end
  end
end
