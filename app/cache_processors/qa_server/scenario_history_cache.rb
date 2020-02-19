# frozen_string_literal: true
# Maintain a cache of data for Authority Connection History table displayed on Monitor Status page
module QaServer
  class ScenarioHistoryCache
    class_attribute :scenario_history_class
    self.scenario_history_class = QaServer::ScenarioRunHistory

    class << self
      include QaServer::CacheKeys

      # Get a summary of the number of days passing/failing for scenario runs during configured time period
      # @param force [Boolean] if true, run the tests even if the cache hasn't expired; otherwise, use cache if not expired
      # @returns [Array<Hash>] count of days with passing/failing tests for each authority
      # @example [auth_name, failing, passing]
      #   { 'agrovoc' => { good: 31, bad: 2 },
      #     'geonames_ld4l_cache' => { good: 32, bad: 1 } }
      def historical_summary(force: false)
        Rails.cache.fetch(cache_key_for_historical_data, expires_in: next_expiry, race_condition_ttl: 30.seconds, force: force) do
          QaServer.config.monitor_logger.debug("(QaServer::ScenarioHistoryCache) - CALCULATING HISTORY of scenario runs (force: force)")
          scenario_history_class.historical_summary
        end
      end

      private

        def cache_key_for_historical_data
          SCENARIO_RUN_HISTORY_DATA_CACHE_KEY
        end

        def next_expiry
          QaServer::CacheExpiryService.cache_expiry
        end
    end
  end
end
