# frozen_string_literal: true
# Maintain a cache of failure data for scenario runs
module QaServer
  class ScenarioRunFailuresCache
    class_attribute :scenario_history_class
    self.scenario_history_class = QaServer::ScenarioRunHistory

    class << self
      include QaServer::CacheKeys

      # Set of failures for a run
      # @param run [QaServer::ScenarioRunRegistry]
      # @returns [Array<Hash>] details for any failing scenarios in the run
      # @example
      #   [ { status: :bad,
      #       authority_name: "geonames_ld4l_cache",
      #       subauthority_name: "area",
      #       service: "ld4l_cache",
      #       action: "search",
      #       url: "/qa/search/linked_data/geonames_ld4l_cache/area?q=France&maxRecords=4",
      #       err_message: "Unable to connect to authority",
      #       scenario_type: :connection
      #       run_time: 11.2 },
      #     { status: :unknown,
      #       authority_name: "oclcfast_ld4l_cache",
      #       subauthority_name: "Person",
      #       service: "ld4l_cache",
      #       action: "search",
      #       url: "/qa/search/linked_data/oclcfast_ld4l_cache/person?q=mark twain&maxRecords=4",
      #       err_message: "Not enough search results returned",
      #       scenario_type: :connection
      #       run_time: 0.123 } ]
      def failures_for_run(run:)
        Rails.cache.fetch(cache_key_for_run_failures(run.id), expires_in: next_expiry, race_condition_ttl: 30.seconds) do
          QaServer.config.monitor_logger.debug("(QaServer::ScenarioRunFailuresCache) - CALCULATING FAILURES for scenario run #{run.id}")
          scenario_history_class.run_failures(run_id: run.id)
        end
      end

    private

      def cache_key_for_run_failures(id)
        "#{SCENARIO_RUN_FAILURE_DATA_CACHE_KEY}--#{id}{"
      end

      def next_expiry
        QaServer::CacheExpiryService.cache_expiry
      end
    end
  end
end
