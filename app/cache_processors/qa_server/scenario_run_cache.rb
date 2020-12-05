# frozen_string_literal: true
# Maintain a cache controlling the execution of scenario tests.
module QaServer
  class ScenarioRunCache
    class << self
      include QaServer::CacheKeys

      # Run connection tests
      def run_tests(force: false)
        Rails.cache.fetch(cache_key, expires_in: next_expiry, race_condition_ttl: 30.seconds, force: force) do
          QaServer.config.monitor_logger.debug("(QaServer::ScenarioRunCache) - KICKING OFF TEST RUN (force: #{force})")
          QaServer::MonitorTestsJob.perform_later
          "Test run initiated at #{QaServer::TimeService.current_time}"
        end
      end

    private

      def cache_key
        "QaServer::ScenarioRunCache.run_tests--latest_run_initiated"
      end

      def next_expiry
        QaServer::CacheExpiryService.cache_expiry
      end
    end
  end
end
