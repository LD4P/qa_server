# frozen_string_literal: true
# Controller for Monitor Status header menu item
module QaServer
  class MonitorStatusController < QaServer::AuthorityValidationController
    class_attribute :presenter_class,
                    :scenario_run_registry_class,
                    :scenario_history_class,
                    :performance_history_class
    self.presenter_class = QaServer::MonitorStatusPresenter
    self.scenario_run_registry_class = QaServer::ScenarioRunRegistry
    self.scenario_history_class = QaServer::ScenarioRunHistory
    self.performance_history_class = QaServer::PerformanceHistory

    # Sets up presenter with data to display in the UI
    def index
      refresh_tests
      historical_data = refresh_history
      performance_data = refresh_performance
      @presenter = presenter_class.new(current_summary: latest_summary,
                                       current_failure_data: latest_failures,
                                       historical_summary_data: historical_data,
                                       performance_data: performance_data)
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

      def expired?
        @expired ||= latest_summary.blank? || latest_summary.run_dt_stamp < yesterday_midnight_et
      end

      def yesterday_midnight_et
        (DateTime.yesterday.midnight.to_time + 4.hours).to_datetime.in_time_zone("Eastern Time (US & Canada)")
      end

      def historical_summary_data(refresh: false)
        # TODO: Make this refresh the same way performance data refreshes.
        #       Requires historical graph to move out of presenter so it can be created here only with refresh.
        if refresh
          @historical_summary_data = scenario_history_class.historical_summary
          # TODO: Need to recreate graph here.  And need to only read the graph in presenter.
        end
        @historical_summary_data ||= scenario_history_class.historical_summary
      end

      def performance_data(refresh: false)
        datatype = performance_datatype(refresh)
        return if datatype == :none
        @performance_data = nil if refresh
        @performance_data ||= performance_history_class.performance_data(datatype: datatype)
      end

      def performance_datatype(refresh) # rubocop:disable Metrics/CyclomaticComplexity
        return :all if display_performance_datatable? && display_performance_graph? && refresh
        return :datatable if display_performance_datatable?
        return :graph if display_performance_graph? && refresh
        :none
      end

      def display_performance_datatable?
        @display_performance_datatable ||= QaServer.config.display_performance_datatable?
      end

      def display_performance_graph?
        @display_performance_graph ||= QaServer.config.display_performance_graph?
      end

      def refresh_tests
        return unless refresh_tests?
        validate(authorities_list)
        update_summary_and_data
      end

      def refresh_history
        historical_summary_data(refresh: refresh_history?)
      end

      def refresh_performance
        performance_data(refresh: refresh_performance?)
      end

      def refresh?
        params.key? :refresh
      end

      def refresh_all?
        params[:refresh].nil? || params[:refresh].casecmp?('all') # nil is for backward compatibility
      end

      def refresh_tests?
        return false unless refresh? || expired?
        refresh_all? || params[:refresh].casecmp?('tests') || expired?
      end

      def refresh_history?
        return false unless refresh?
        refresh_all? || params[:refresh].casecmp?('history')
      end

      def refresh_performance?
        return false unless refresh?
        refresh_all? || params[:refresh].casecmp?('performance')
      end
  end
end
