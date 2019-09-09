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

    def_delegators :@performance_presenter, :performance_data, :performance_data?, :display_performance?, :display_performance_graph?,
                   :display_performance_datatable?, :performance_data_authority_name, :performance_for_day_graph, :performance_for_month_graph,
                   :performance_for_year_graph, :lifetime_stats, :min_load, :min_normalization, :min_full_request, :max_load,
                   :max_normalization, :max_full_request, :avg_load, :avg_normalization, :avg_full_request, :min_load_style,
                   :min_normalization_style, :min_full_request_style, :max_load_style, :max_normalization_style, :max_full_request_style,
                   :avg_load_style, :avg_normalization_style, :avg_full_request_style, :performance_style_class, :max_threshold_exceeded,
                   :min_threshold_not_met, :performance_graphs, :performance_graph, :performance_graph_authority, :performance_graph_label,
                   :performance_default_graph_id, :performance_graph_id, :performance_graph_data_section_id, :performance_graph_data_section_base_id,
                   :performance_data_section_class, :performance_day_graph_selected?, :performance_month_graph_selected?,
                   :performance_year_graph_selected?
  end
end
