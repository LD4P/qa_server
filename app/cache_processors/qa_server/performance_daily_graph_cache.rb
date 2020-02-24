# frozen_string_literal: true
# Generate graphs for the past 30 days using cached data.  Graphs are generated only if the cache has expired.
module QaServer
  class PerformanceDailyGraphCache
    class_attribute :authority_list_class, :graph_data_service, :graphing_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.graph_data_service = QaServer::PerformanceGraphDataService
    self.graphing_service = QaServer::PerformanceGraphingService

    class << self
      include QaServer::CacheKeys

      # Generates graphs for the past 30 days for :search, :fetch, and :all actions for each authority.
      # @param force [Boolean] if true, generate graphs even if the cache hasn't expired; otherwise, use cache if not expired
      def generate_graphs(force: false)
        return unless QaServer::CacheExpiryService.cache_expired?(key: daily_cache_key_for_force, force: force, next_expiry: next_expiry)
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceDailyGraphCache) - KICKING OFF DAILY GRAPHS GENERATION (force: #{force})")
        QaServer::PerformanceDailyGraphsJob.perform_later
      end

      private

        def daily_cache_key_for_force
          cache_key_for_force(PERFORMANCE_GRAPH_DAILY_DATA_CACHE_KEY)
        end

        def next_expiry
          default_next_expiry
        end
    end
  end
end
