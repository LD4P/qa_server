# frozen_string_literal: true
# Provide access to the scenario_run_registry database table which registers each run of tests made over time.
module QaServer
  class ScenarioRunRegistry < ActiveRecord::Base
    self.table_name = 'scenario_run_registry'
    has_many :scenario_run_history, foreign_key: :scenario_run_registry_id

    # @return [ScenarioRunRegistry] registry data for latest run (e.g. id, dt_stamp)
    def self.latest_run
      return nil unless QaServer::ScenarioRunRegistry.last
      QaServer::ScenarioRunRegistry.last # Can we count on last to always be the one with the latest dt_stamp?
      # latest_run = ScenarioRunRegistry.all.sort(:dt_stamp).last
      # return nil if latest_run.blank?
      # latest_run.id
    end

    # @return [Integer] id for latest test run
    # @deprecated Not used anywhere. Being removed.
    def self.latest_run_id
      latest = latest_run
      return nil unless latest
      lastest.id
    end
    deprecation_deprecate latest_run_id: "Not used anywhere. Being removed."

    # @return [ActiveSupport::TimeWithZone] datetime stamp of first registered run
    def self.first_run_dt
      Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer::CacheExpiryService.cache_expiry, race_condition_ttl: 30.seconds) do
        QaServer::ScenarioRunRegistry.first.dt_stamp
      end
    end

    # Register and save latest test run results
    # @param scenarios_results [Array<Hash>] results of latest test run
    def self.save_run(scenarios_results:)
      run = QaServer::ScenarioRunRegistry.create(dt_stamp: QaServer::TimeService.current_time)
      scenarios_results.each { |result| QaServer::ScenarioRunHistory.save_result(run_id: run.id, scenario_result: result) }
    end
  end
end
