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
      @current_status_presenter = QaServer::MonitorStatus::CurrentStatusPresenter.new(parent: self, current_summary: current_summary, current_failure_data: current_failure_data)
      @history_presenter = QaServer::MonitorStatus::HistoryPresenter.new(parent: self, historical_summary_data: historical_summary_data)
      @performance_presenter = QaServer::MonitorStatus::PerformancePresenter.new(parent: self, performance_data: performance_data)
    end

    def_delegators :@current_status_presenter, :last_updated_dt, :last_updated, :first_updated_dt, :first_updated, :authorities_count,
                   :failing_authorities_count, :authorities_count_style, :tests_count, :passing_tests_count, :failing_tests_count,
                   :failing_tests_style, :failures, :failures?

    def_delegators :@history_presenter, :historical_summary, :history?, :historical_graph, :status_style_class, :status_label,
                   :historical_data_authority_name, :days_authority_passing, :days_authority_failing, :days_authority_tested,
                   :percent_authority_failing, :percent_authority_failing_str, :failure_style_class, :passing_style_class,
                   :display_history_details?, :display_historical_graph?, :display_historical_datatable?, :history_start, :history_end

    def_delegators :@performance_presenter, :performance_data, :performance_data?, :display_performance?, :display_performance_graph?,
                   :display_performance_datatable?, :performance_data_authority_name, :performance_for_day_graph, :performance_for_month_graph,
                   :performance_for_year_graph, :datatable_search_stats, :datatable_fetch_stats, :datatable_all_actions_stats,
                   :low_retrieve, :low_graph_load, :low_normalization, :low_full_request, :high_retrieve, :high_graph_load,
                   :high_normalization, :high_full_request, :avg_retrieve, :avg_graph_load, :avg_normalization, :avg_full_request,
                   :datatable_data_style, :low_load_style, :low_normalization_style, :low_full_request_style, :high_load_style,
                   :high_normalization_style, :high_full_request_style, :avg_load_style, :avg_normalization_style, :avg_full_request_style,
                   :performance_style_class, :high_threshold_exceeded, :low_threshold_not_met, :performance_graphs, :performance_graph,
                   :performance_graph_authority, :performance_graph_label, :performance_default_graph_id, :performance_graph_id,
                   :performance_graph_data_section_id, :performance_graph_data_section_base_id, :performance_data_section_class,
                   :performance_day_graph?, :performance_month_graph?, :performance_year_graph?, :performance_all_actions_graph?,
                   :performance_search_graph?, :performance_fetch_graph?, :performance_table_description, :performance_graph_time_period,
                   :performance_graph_action, :performance_data_start, :performance_data_end
  end
end
