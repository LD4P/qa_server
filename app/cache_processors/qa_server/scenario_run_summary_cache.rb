# frozen_string_literal: true
# Maintain a cache of summary test data for scenario runs
module QaServer
  class ScenarioRunSummaryCache
    class_attribute :scenario_history_class
    self.scenario_history_class = QaServer::ScenarioRunHistory

    class << self
      include QaServer::CacheKeys

      # Summary for a run
      # @param run [QaServer::ScenarioRunRegistry]
      # @returns [QaServer::ScenarioRunSummary] statistics on the requested run
      # @example ScenarioRunSummary includes methods for accessing
      #   * run_id           [Integer] e.g. 14
      #   * run_dt_stamp     [ActiveSupport::TimeWithZone] e.g. Wed, 19 Feb 2020 16:01:07 UTC +00:00
      #   * authority_count  [Integer] e.g. 22
      #   * failing_authority_count [Integer] e.g. 1
      #   * passing_scenario_count  [Integer] e.g. 156
      #   * failing_scenario_count  [Integer] e.g. 3
      #   * total_scenario_count    [Integer] e.g. 159
      def summary_for_run(run:)
        Rails.cache.fetch(cache_key_for_run_summary(run.id), expires_in: next_expiry, race_condition_ttl: 30.seconds) do
          QaServer.config.monitor_logger.debug("(QaServer::ScenarioRunSummaryCache) - CALCULATING SUMMARY for scenario run #{run.id}")
          scenario_history_class.run_summary(scenario_run: run)
        end
      end

      private

        def cache_key_for_run_summary(id)
          "#{SCENARIO_RUN_SUMMARY_DATA_CACHE_KEY}--#{id}"
        end

        def next_expiry
          QaServer::CacheExpiryService.cache_expiry
        end
    end
  end
end
