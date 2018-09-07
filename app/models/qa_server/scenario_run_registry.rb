# Provide access to the scenario_run_registry database table which registers each run of tests made over time.
module QaServer
  class ScenarioRunRegistry < ActiveRecord::Base
    self.table_name = 'scenario_run_registry'
    has_many :scenario_run_history, foreign_key: :scenario_run_registry_id

    # Get the latest saved run of scenarios.
    def self.latest_run
      return nil unless QaServer::ScenarioRunRegistry.last
      QaServer::ScenarioRunRegistry.last # Can we count on last to always be the one with the latest dt_stamp?
      # latest_run = ScenarioRunRegistry.all.sort(:dt_stamp).last
      # return nil if latest_run.blank?
      # latest_run.id
    end

    # Get the latest saved status.
    def self.latest_run_id
      latest = latest_run
      return nil unless latest
      lastest.id
    end

    def self.save_run(scenarios_results:)
      run = QaServer::ScenarioRunRegistry.create(dt_stamp: dt_stamp_now_et)
      scenarios_results.each { |result| QaServer::ScenarioRunHistory.save_result(run_id: run.id, scenario_result: result) }
    end

    private

      def self.dt_stamp_now_et
        Time.now.in_time_zone("Eastern Time (US & Canada)")
      end
  end
end
