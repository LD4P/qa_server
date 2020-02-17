# frozen_string_literal: true
# Controller for Monitor Status header menu item
module QaServer
  class MonitorStatusController < ApplicationController
    layout 'qa_server'

    include QaServer::AuthorityValidationBehavior

    class_attribute :presenter_class,
                    :scenario_run_registry_class,
                    :scenario_history_class,
                    :performance_history_class,
                    :graphing_service_class
    self.presenter_class = QaServer::MonitorStatusPresenter
    self.scenario_run_registry_class = QaServer::ScenarioRunRegistry
    self.scenario_history_class = QaServer::ScenarioRunHistory
    self.performance_history_class = QaServer::PerformanceHistory
    self.graphing_service_class = QaServer::PerformanceGraphingService

    # Sets up presenter with data to display in the UI
    def index
      log_header
      latest_test_run
      @presenter = presenter_class.new(current_summary: latest_summary,
                                       current_failure_data: latest_failures,
                                       historical_summary_data: historical_data,
                                       performance_data: performance_table_data)
      update_performance_graphs
      render 'index', status: :internal_server_error if latest_summary.failing_authority_count.positive?
    end

    private

      # Sets @latest_test_run [QaServer::ScenarioRunRegistry]
      def latest_test_run
        @latest_test_run ||= latest_test_run_from_cache
      end

      # cache of latest run; runs tests if cache is expired
      # @see #latest_test_run_from_temp_cache
      def latest_test_run_from_cache
        Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer::MonitorCacheService.cache_expiry, race_condition_ttl: 5.minutes, force: refresh_tests?) do
          QaServer.config.monitor_logger.info("(#{self.class}##{__method__}) get latest run of monitoring tests - cache expired or refresh requested (force: #{refresh_tests?})")
          QaServer::MonitorTestsJob.perform_later
          scenario_run_registry_class.latest_run
        end
      end

      # Sets @latest_summary [QaServer::ScenarioRunSummary]
      def latest_summary
        scenario_history_class.run_summary(scenario_run: latest_test_run, force: refresh_tests?)
      end

      def latest_failures
        scenario_history_class.run_failures(run_id: latest_test_run.id, force: refresh_tests?)
      end

      # Sets @historical_data [Array<Hash>]
      def historical_data
        scenario_history_class.historical_summary(force: refresh_history?)
      end

      # Sets @performance_table_data [Hash<Hash>]
      def performance_table_data
        display_performance_datatable? ? performance_history_class.performance_table_data(force: refresh_performance?) : {}
      end

      def update_performance_graphs
        return unless display_performance_graph?
        data = performance_history_class.performance_graph_data(force: refresh_performance?)
        graphing_service_class.create_performance_graphs(performance_data: data)
      end

      def display_performance_datatable?
        @display_performance_datatable ||= QaServer.config.display_performance_datatable?
      end

      def display_performance_graph?
        @display_performance_graph ||= QaServer.config.display_performance_graph?
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

      def log_header
        QaServer.config.monitor_logger.debug("-------------------------------------  monitor status  ---------------------------------")
        QaServer.config.monitor_logger.info("(#{self.class}##{__method__}) monitor status page request (refresh_tests? # #{refresh_tests?}, " \
                                         "refresh_history? # #{refresh_history?}, refresh_performance? # #{refresh_performance?})")
      end
  end
end
