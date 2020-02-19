# frozen_string_literal: true
# Controller for Monitor Status header menu item
module QaServer
  class MonitorStatusController < ApplicationController # rubocop:disable Metrics/ClassLength
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
      commit_cache if commit_cache?
      @presenter = presenter_class.new(current_summary: latest_summary,
                                       current_failure_data: latest_failures,
                                       historical_summary_data: historical_data,
                                       performance_data: performance_table_data)
      update_performance_graphs
      QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}) DONE rendering")
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
        Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer::CacheExpiryService.cache_expiry, race_condition_ttl: 5.minutes, force: refresh_tests?) do
          QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}) get latest run of monitoring tests - cache expired or refresh requested (force: #{refresh_tests?})")
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

      def performance_table_data
        return {} unless QaServer.config.display_performance_graph?
        QaServer::PerformanceDatatableCache.data(force: refresh_performance_table?)
      end

      def update_performance_graphs
        return unless QaServer.config.display_performance_graph?
        QaServer::PerformanceHourlyGraphCache.generate_graphs(force: refresh_performance_graphs?)
        QaServer::PerformanceDailyGraphCache.generate_graphs(force: refresh_performance_graphs?)
        QaServer::PerformanceMonthlyGraphCache.generate_graphs(force: refresh_performance_graphs?)
      end

      def refresh?
        params.key?(:refresh) && validate_auth_reload_token("refresh status")
      end

      def refresh_all?
        return false unless refresh?
        params[:refresh].nil? || params[:refresh].casecmp?('all') # nil is for backward compatibility
      end

      def refresh_tests?
        refresh? ? (refresh_all? || params[:refresh].casecmp?('tests')) : false
      end

      def refresh_history?
        refresh? ? (refresh_all? || params[:refresh].casecmp?('history')) : false
      end

      def refresh_history_table?
        refresh? ? (refresh_history? || params[:refresh].casecmp?('history_table')) : false
      end

      def refresh_history_graph?
        refresh? ? (refresh_history? || params[:refresh].casecmp?('history_graph')) : false
      end

      def refresh_performance?
        refresh? ? (refresh_all? || params[:refresh].casecmp?('performance')) : false
      end

      def refresh_performance_table?
        refresh? ? (refresh_performance? || params[:refresh].casecmp?('performance_table')) : false
      end

      def refresh_performance_graphs?
        refresh? ? (refresh_performance? || params[:refresh].casecmp?('performance_graphs')) : false
      end

      def commit_cache?
        params.key?(:commit) && validate_auth_reload_token("commit cache")
      end

      def commit_cache
        QaServer.config.performance_cache.write_all
      end

      def validate_auth_reload_token(action)
        token = params.key?(:auth_token) ? params[:auth_token] : nil
        valid = Qa.config.valid_authority_reload_token?(token)
        return true if valid
        msg = "Permission denied. Unable to #{action}."
        logger.warn msg
        flash.now[:error] = msg
        false
      end

      def log_header
        QaServer.config.monitor_logger.debug("-------------------------------------  monitor status  ---------------------------------")
        QaServer.config.monitor_logger.debug("refresh_all? #{refresh_all?}, refresh_tests? #{refresh_tests?}")
        QaServer.config.monitor_logger.debug("refresh_history? #{refresh_history?}, refresh_history_table? #{refresh_history_table?}, refresh_history_graph? #{refresh_history_graph?}")
        QaServer.config.monitor_logger.debug("refresh_performance? #{refresh_performance?}, refresh_performance_table? #{refresh_performance_table?}, " \
                                             "refresh_performance_graphs? #{refresh_performance_graphs?})")
      end
  end
end
