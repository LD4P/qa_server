# frozen_string_literal: true
# Controller for Monitor Status header menu item
module QaServer
  class MonitorStatusController < ApplicationController # rubocop:disable Metrics/ClassLength
    layout 'qa_server'

    include QaServer::AuthorityValidationBehavior

    class_attribute :presenter_class,
                    :scenario_run_registry_class
    self.presenter_class = QaServer::MonitorStatusPresenter
    self.scenario_run_registry_class = QaServer::ScenarioRunRegistry

    # Sets up presenter with data to display in the UI
    def index
      log_header
      perform_updates
      commit_cache if commit_cache?
      @presenter = presenter_class.new(current_summary: latest_summary,
                                       current_failure_data: latest_failures,
                                       historical_summary_data: historical_data,
                                       historical_up_down_data: historical_up_down_data,
                                       performance_data: performance_table_data)
      QaServer.config.monitor_logger.debug("~~~~~~~~ DONE rendering monitor status")
      render 'index', status: :internal_server_error if latest_summary&.failing_authority_count&.positive?
    end

  private

    def perform_updates
      update_tests
      update_historical_graph
      update_performance_graphs
    end

    def update_tests
      QaServer::ScenarioRunCache.run_tests(force: refresh_tests?)
    end

    # Sets @latest_test_run [QaServer::ScenarioRunRegistry]
    def latest_test_run
      @latest_test_run ||= scenario_run_registry_class.latest_run
    end

    # @returns [QaServer::ScenarioRunSummary] summary statistics on the latest run
    def latest_summary
      latest_test_run ? QaServer::ScenarioRunSummaryCache.summary_for_run(run: latest_test_run) : nil
    end

    # @returns [Array<Hash>] scenario details for any failing scenarios in the latest run
    # @see QaServer::ScenarioRunHistory#run_failures for structure of output
    def latest_failures
      latest_test_run ? QaServer::ScenarioRunFailuresCache.failures_for_run(run: latest_test_run) : nil
    end

    # Get a summary level of historical data
    # @returns [Array<Hash>] summary of passing/failing tests for each authority
    # @see QaServer::ScenarioRunHistory#historical_summary for structure of output
    def historical_data
      @historical_data ||= QaServer::ScenarioHistoryCache.historical_summary(force: refresh_history?)
    end

    # Get a summary level of historical data
    # @returns [Array<Hash>] summary of passing/failing tests for each authority
    # @see QaServer::ScenarioRunHistory#historical_summary for structure of output
    def historical_up_down_data
      @historical_up_down_data ||= QaServer::ScenarioHistoryCache.historical_up_down_data(force: refresh_history?)
    end

    def update_historical_graph
      return unless QaServer.config.display_historical_graph?
      QaServer::ScenarioHistoryGraphCache.generate_graph(data: historical_data, force: refresh_history?)
    end

    def performance_table_data
      return {} unless QaServer.config.display_performance_datatable?
      QaServer::PerformanceDatatableCache.data(force: refresh_performance_table?)
    end

    def update_performance_graphs
      return unless QaServer.config.display_performance_graph?
      QaServer::PerformanceDayGraphCache.generate_graphs(force: refresh_performance_graphs?)
      QaServer::PerformanceMonthGraphCache.generate_graphs(force: refresh_performance_graphs?)
      QaServer::PerformanceYearGraphCache.generate_graphs(force: refresh_performance_graphs?)
    end

    def refresh?
      return @refresh unless @refresh.nil?
      @refresh ||= params.key?(:refresh) && validate_auth_reload_token("refresh status")
    end

    def refresh_all?
      return false unless refresh?
      params[:refresh].nil? || params[:refresh].casecmp?('all') # nil is for backward compatibility
    end

    def refresh_tests?
      return @refresh_tests unless @refresh_tests.nil?
      @refresh_tests = refresh? && (refresh_all? || params[:refresh].casecmp?('tests'))
      if @refresh_tests
        msg = I18n.t('qa_server.monitor_status.refreshing_tests')
        logger.info msg
        flash.now[:success] = msg
      end
      @refresh_tests
    end

    def refresh_history?
      return @refresh_history unless @refresh_history.nil?
      @refresh_history = refresh? && (refresh_all? || params[:refresh].casecmp?('history'))
      if @refresh_history
        msg = I18n.t('qa_server.monitor_status.refreshing_history')
        logger.info msg
        flash.now[:success] = msg
      end
      @refresh_history
    end

    def refresh_performance?
      return @refresh_performance unless @refresh_performance.nil?
      @refresh_performance = refresh? && (refresh_all? || params[:refresh].casecmp?('performance'))
      if @refresh_performance
        msg = I18n.t('qa_server.monitor_status.refreshing_performance')
        logger.info msg
        flash.now[:success] = msg
      end
      @refresh_performance
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
      msg = I18n.t('qa_server.monitor_status.permission_denied', action: action)
      logger.warn msg
      flash.now[:error] = msg
      false
    end

    def log_header
      QaServer.config.monitor_logger.debug("------------------------------------  monitor status  -----------------------------------")
      QaServer.config.monitor_logger.debug("refresh_all? #{refresh_all?}, refresh_tests? #{refresh_tests?}, refresh_history? #{refresh_history?}")
      QaServer.config.monitor_logger.debug("refresh_performance? #{refresh_performance?}, refresh_performance_table? #{refresh_performance_table?}, " \
                                           "refresh_performance_graphs? #{refresh_performance_graphs?})")
    end
  end
end
