# frozen_string_literal: true
# This presenter class provides all data needed by the view that monitors status of authorities.
module QaServer
  class MonitorStatusPresenter
    extend Forwardable

    # @param current_summary [ScenarioRunSummary] summary status of the latest run of test scenarios
    # @param current_data [Array<Hash>] current set of failures for the latest test run, if any
    # @param historical_summary_data [Array<Hash>] summary of past failuring runs per authority to drive chart
    # @param performance_data [Hash<Hash>] performance data
    def initialize(current_summary:, current_failure_data:, historical_summary_data:, performance_data:)
      @current_status_presenter = QaServer::MonitorStatus::CurrentStatusPresenter.new(current_summary: current_summary, current_failure_data: current_failure_data)
      @history_presenter = QaServer::MonitorStatus::HistoryPresenter.new(historical_summary_data: historical_summary_data)
      @performance_presenter = QaServer::MonitorStatus::PerformancePresenter.new(performance_data: performance_data)
    end

    def_delegators :@current_status_presenter, :last_updated, :first_updated, :authorities_count, :failing_authorities_count,
                   :authorities_count_style, :tests_count, :passing_tests_count, :failing_tests_count, :failing_tests_style,
                   :failures, :failures?

    def_delegators :@history_presenter, :historical_summary, :history?, :historical_graph, :status_style_class, :status_label,
                   :historical_data_authority_name, :days_authority_passing, :days_authority_failing, :days_authority_tested,
                   :percent_authority_failing, :percent_authority_failing_str, :failure_style_class, :passing_style_class,
                   :display_history_details?, :display_historical_graph?, :display_historical_datatable?

    def_delegators :@performance_presenter, :performance_data?, :performance_for_day_graph, :performance_for_month_graph,
                   :performance_for_year_graph, :performance_style_class, :display_performance_details?, :display_performance_graph?,
                   :display_performance_datatable?, :max_threshold_exceeded, :min_threshold_not_met
  end
end
