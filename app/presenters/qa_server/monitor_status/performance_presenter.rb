# frozen_string_literal: true
# This presenter class provides performance data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class PerformancePresenter # rubocop:disable Metrics/ClassLength
    class_attribute :performance_history_class
    self.performance_history_class = QaServer::PerformanceHistory

    include QaServer::MonitorStatus::GruffGraph

    ALL_AUTHS = performance_history_class::PERFORMANCE_ALL_KEY
    STATS = performance_history_class::PERFORMANCE_STATS_KEY

    FOR_DAY = performance_history_class::PERFORMANCE_FOR_DAY_KEY
    BY_HOUR = performance_history_class::PERFORMANCE_BY_HOUR_KEY
    FOR_MONTH = performance_history_class::PERFORMANCE_FOR_MONTH_KEY
    BY_DAY = performance_history_class::PERFORMANCE_BY_DAY_KEY
    FOR_YEAR = performance_history_class::PERFORMANCE_FOR_YEAR_KEY
    BY_MONTH = performance_history_class::PERFORMANCE_BY_MONTH_KEY

    SUM_LOAD = performance_history_class::SUM_LOAD_TIME_KEY
    SUM_NORMALIZATION = performance_history_class::SUM_NORMALIZATION_TIME_KEY
    SUM_COMBINED = performance_history_class::SUM_COMBINED_TIME_KEY
    MIN_LOAD = performance_history_class::MIN_LOAD_TIME_KEY
    MIN_NORMALIZATION = performance_history_class::MIN_NORMALIZATION_TIME_KEY
    MIN_COMBINED = performance_history_class::MIN_COMBINED_TIME_KEY
    MAX_LOAD = performance_history_class::MAX_LOAD_TIME_KEY
    MAX_NORMALIZATION = performance_history_class::MAX_NORMALIZATION_TIME_KEY
    MAX_COMBINED = performance_history_class::MAX_COMBINED_TIME_KEY
    AVG_LOAD = performance_history_class::AVG_LOAD_TIME_KEY
    AVG_NORMALIZATION = performance_history_class::AVG_NORMALIZATION_TIME_KEY
    AVG_COMBINED = performance_history_class::AVG_COMBINED_TIME_KEY

    # @param performance_data [Hash<Hash>] performance data
    def initialize(performance_data:)
      @performance_data = performance_data[ALL_AUTHS]
    end

    def performance_data?
      @performance_data.present?
    end

    def performance_for_day_graph
      performance_graph_file(rework_performance_data_for_gruff(@performance_data[FOR_DAY], BY_HOUR),
                             performance_for_day_graph_full_path,
                             performance_for_day_graph_filename,
                             I18n.t('qa_server.monitor_status.performance.x_axis_hour'))
    end

    def performance_for_month_graph
      performance_graph_file(rework_performance_data_for_gruff(@performance_data[FOR_MONTH], BY_DAY),
                             performance_for_month_graph_full_path,
                             performance_for_month_graph_filename,
                             I18n.t('qa_server.monitor_status.performance.x_axis_day'))
    end

    def performance_for_year_graph
      performance_graph_file(rework_performance_data_for_gruff(@performance_data[FOR_YEAR], BY_MONTH),
                             performance_for_year_graph_full_path,
                             performance_for_year_graph_filename,
                             I18n.t('qa_server.monitor_status.performance.x_axis_month'))
    end

    def performance_style_class(performance_entry, stat)
      return "status-bad" if max_threshold_exceeded(performance_entry, stat)
      return "status-unknown" if min_threshold_not_met(performance_entry, stat)
      "status-neutral"
    end

    def display_performance_details?
      display_performance_graph? || display_performance_datatable?
    end

    def display_performance_graph?
      QaServer.config.display_performance_graph?
    end

    def display_performance_datatable?
      QaServer.config.display_performance_datatable?
    end

    def max_threshold_exceeded(_performance_entry, _stat)
      # TODO: stubbed
      false
    end

    def min_threshold_not_met(_performance_entry, _stat)
      # TODO: stubbed
      false
    end

    private

      def performance_graph_theme(g, x_axis_label)
        g.theme_pastel
        g.colors = ['#81adf4', '#8696b0', '#06578a']
        g.marker_font_size = 12
        g.x_axis_increment = 10
        g.x_axis_label = x_axis_label
        g.y_axis_label = I18n.t('qa_server.monitor_status.performance.y_axis_ms')
        g.dot_radius = 3
        g.line_width = 2
        g.minimum_value = 0
        g.maximum_value = 1000
      end

      def performance_for_day_graph_filename
        'performance_for_day_graph.png'
      end

      def performance_for_day_graph_full_path
        graph_full_path(performance_for_day_graph_filename)
      end

      def performance_for_month_graph_filename
        'performance_for_month_graph.png'
      end

      def performance_for_month_graph_full_path
        graph_full_path(performance_for_month_graph_filename)
      end

      def performance_for_year_graph_filename
        'performance_for_year_graph.png'
      end

      def performance_for_year_graph_full_path
        graph_full_path(performance_for_year_graph_filename)
      end

      def rework_performance_data_for_gruff(performance_data, label_key)
        labels = {}
        load_data = []
        normalization_data = []
        combined_data = []
        performance_data.each do |i, data|
          labels[i] = data[label_key]
          load_data << data[STATS][AVG_LOAD]
          normalization_data << data[STATS][AVG_NORMALIZATION]
          combined_data << data[STATS][AVG_COMBINED]
        end
        [labels, load_data, normalization_data, combined_data]
      end

      def performance_graph_file(performance_data, performance_graph_full_path, performance_graph_filename, x_axis_label)
        g = Gruff::Line.new
        performance_graph_theme(g, x_axis_label)
        g.title = ''
        g.labels = performance_data[0]
        g.data(I18n.t('qa_server.monitor_status.performance.load_time_ms'), performance_data[1])
        g.data(I18n.t('qa_server.monitor_status.performance.normalization_time_ms'), performance_data[2])
        g.data(I18n.t('qa_server.monitor_status.performance.combined_time_ms'), performance_data[3])
        g.write performance_graph_full_path
        File.join(graph_relative_path, performance_graph_filename)
      end
  end
end
