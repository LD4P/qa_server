# frozen_string_literal: true
# Controller for Monitor Status header menu item
module QaServer
  class MonitorStatusController < QaServer::AuthorityValidationController
    class_attribute :presenter_class,
                    :scenario_run_registry_class,
                    :scenario_history_class

    self.presenter_class = QaServer::MonitorStatusPresenter
    self.scenario_run_registry_class = QaServer::ScenarioRunRegistry
    self.scenario_history_class = QaServer::ScenarioRunHistory

    # Sets up presenter with data to display in the UI
    def index
      if refresh? || expired?
        validate(authorities_list)
        update_summary_and_data
      end
      # TODO: Include historical data and performance data too
      @presenter = presenter_class.new(current_summary: latest_summary,
                                       current_failure_data: latest_failures,
                                       historical_summary_data: historical_summary_data,
                                       performance_data: [])
      render 'index', status: :internal_server_error if latest_summary.failing_authority_count.positive?
    end

    private

      def latest_run
        @latest_run ||= scenario_run_registry_class.latest_run
      end

      def latest_summary
        @latest_summary ||= scenario_history_class.run_summary(scenario_run: latest_run)
      end

      def latest_failures
        @status_data ||= scenario_history_class.run_failures(run_id: latest_run.id)
      end

      def update_summary_and_data
        scenario_run_registry_class.save_run(scenarios_results: status_log.to_a)
        @latest_summary = nil # reset so next request recalculates
        @latest_failures = nil # reset so next request recalculates
      end

      def historical_summary_data
        @historical_summary_data ||= scenario_history_class.historical_summary
      end

      def expired?
        latest_summary.blank? || latest_summary.run_dt_stamp < yesterday_midnight_et
      end

      def yesterday_midnight_et
        (DateTime.yesterday.midnight.to_time + 4.hours).to_datetime.in_time_zone("Eastern Time (US & Canada)")
      end

      def refresh?
        params.key? :refresh
      end
  end
end
