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
      latest_run
      @presenter = presenter_class.new(current_summary: latest_summary,
                                       current_failure_data: latest_failures,
                                       historical_summary_data: historical_data,
                                       performance_data: performance_data)
      render 'index', status: :internal_server_error if latest_summary.failing_authority_count.positive?
    end

    private

      # Sets @latest_run [QaServer::ScenarioRunRegistry]
      def latest_run
        Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer.cache_expiry, race_condition_ttl: 1.hour, force: refresh_tests?) do
          Rails.logger.info("#{self.class}##{__method__} - Running Tests - cache expired or refresh requested (#{refresh_tests?})")
          validate(authorities_list)
          scenario_run_registry_class.save_run(scenarios_results: status_log.to_a)
          scenario_run_registry_class.latest_run
        end
      end

      # Sets @latest_summary [QaServer::ScenarioRunSummary]
      def latest_summary
        scenario_history_class.run_summary(scenario_run: latest_run, force: refresh_tests?)
      end

      def latest_failures
        scenario_history_class.run_failures(run_id: latest_run.id, force: refresh_tests?)
      end

      # Sets @historical_data [Array<Hash>]
      def historical_data
        scenario_history_class.historical_summary(force: refresh_history?)
      end

      # Sets @performance_data [Hash<Hash>]
      def performance_data
        performance_history_class.performance_data(datatype: performance_datatype, force: refresh_performance?)
      end

      def performance_datatype
        return :all if display_performance_datatable? && display_performance_graph?
        return :datatable if display_performance_datatable?
        return :graph if display_performance_graph?
        :none
      end

      def display_performance_datatable?
        @display_performance_datatable ||= QaServer.config.display_performance_datatable?
      end

      def display_performance_graph?
        @display_performance_graph ||= QaServer.config.display_performance_graph?
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
        return false unless refresh?
        params[:refresh].nil? || params[:refresh].casecmp?('all') # nil is for backward compatibility
      end

      def refresh_tests?
        return false unless refresh?
        refresh_all? || params[:refresh].casecmp?('tests')
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
