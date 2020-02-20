# frozen_string_literal: true
# Generate graphs for the past 30 days using cached data.  Graphs are generated only if the cache has expired.
module QaServer
  class ScenarioHistoryGraphCache
    class_attribute :graphing_service
    self.graphing_service = QaServer::HistoryGraphingService

    class << self
      include QaServer::CacheKeys
      include QaServer::MonitorStatus::GruffGraph

      HISTORICAL_GRAPH_FILENAME = 'historical_side_stacked_bar.png'

      # Generates graphs for the past 30 days for :search, :fetch, and :all actions for each authority.
      # @param force [Boolean] if true, run the tests even if the cache hasn't expired; otherwise, use cache if not expired
      def generate_graph(data:, force: false)
        return unless QaServer::CacheExpiryService.cache_expired?(key: cache_key_for_force, force: force, next_expiry: next_expiry)
        QaServer.config.monitor_logger.debug("(QaServer::ScenarioHistoryGraphCache) - GENERATING historical summary graph (force: #{force})")
        graphing_service.generate_graph(data)
      end

      private

        def cache_key_for_force
          "#{SCENARIO_RUN_HISTORY_GRAPH_CACHE_KEY}--force"
        end

        def next_expiry
          QaServer::CacheExpiryService.cache_expiry
        end
    end
  end
end
