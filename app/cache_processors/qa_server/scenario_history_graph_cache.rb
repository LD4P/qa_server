# frozen_string_literal: true
# Generate graphs for the past 30 days using cached data.  Graphs are generated only if the cache has expired.
module QaServer
  class ScenarioHistoryGraphCache
    class << self
      # Generates graphs for the past 30 days for :search, :fetch, and :all actions for each authority.
      # @param force [Boolean] if true, run the tests even if the cache hasn't expired; otherwise, use cache if not expired
      def generate_graph(data:, force: false)
        Rails.cache.fetch(cache_key, expires_in: next_expiry, race_condition_ttl: 30.seconds, force: force) do
          QaServer.config.monitor_logger.debug("(QaServer::ScenarioHistoryGraphCache) - KICKING OFF HISTORY GRAPH GENERATION (force: #{force})")
          QaServer::HistoryGraphJob.perform_later(data: data)
          "Graph generation initiated at #{QaServer::TimeService.current_time}"
        end
      end

    private

      def cache_key
        "QaServer::ScenarioHistoryGraphCache.generate_graph--latest_generation_initiated"
      end

      def next_expiry
        QaServer::CacheExpiryService.cache_expiry
      end
    end
  end
end
