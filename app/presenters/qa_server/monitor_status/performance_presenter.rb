# frozen_string_literal: true
# This presenter class provides performance data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class PerformancePresenter # rubocop:disable Metrics/ClassLength
    include QaServer::MonitorStatus::GruffGraph
    include QaServer::PerformanceHistoryDataKeys

    # @param performance_data [Hash<Hash>] performance data
    def initialize(performance_data:)
      @performance_data = performance_data
    end

    attr_reader :performance_data

    def performance_data?
      performance_data.present?
    end

    def display_performance?
      display_performance_graph? || display_performance_datatable?
    end

    def display_performance_graph?
      QaServer.config.display_performance_graph?
    end

    def display_performance_datatable?
      QaServer.config.display_performance_datatable?
    end

    def performance_data_authority_name(entry)
      entry.keys.first
    end

    def performance_for_day_graph
      performance_graph_file(rework_performance_data_for_gruff(all_authorities_performance_data[FOR_DAY], BY_HOUR),
                             performance_for_day_graph_full_path,
                             performance_for_day_graph_filename,
                             I18n.t('qa_server.monitor_status.performance.x_axis_hour'))
    end

    def performance_for_month_graph
      performance_graph_file(rework_performance_data_for_gruff(all_authorities_performance_data[FOR_MONTH], BY_DAY),
                             performance_for_month_graph_full_path,
                             performance_for_month_graph_filename,
                             I18n.t('qa_server.monitor_status.performance.x_axis_day'))
    end

    def performance_for_year_graph
      performance_graph_file(rework_performance_data_for_gruff(all_authorities_performance_data[FOR_YEAR], BY_MONTH),
                             performance_for_year_graph_full_path,
                             performance_for_year_graph_filename,
                             I18n.t('qa_server.monitor_status.performance.x_axis_month'))
    end

    def lifetime_stats(authority_data)
      authority_data[FOR_LIFETIME]
    end

    def min_load(stats)
      format_stat stats[MIN_LOAD]
    end

    def min_normalization(stats)
      format_stat stats[MIN_NORM]
    end

    def min_full_request(stats)
      format_stat stats[MIN_FULL]
    end

    def max_load(stats)
      format_stat stats[MAX_LOAD]
    end

    def max_normalization(stats)
      format_stat stats[MAX_NORM]
    end

    def max_full_request(stats)
      format_stat stats[MAX_FULL]
    end

    def avg_load(stats)
      format_stat stats[AVG_LOAD]
    end

    def avg_normalization(stats)
      format_stat stats[AVG_NORM]
    end

    def avg_full_request(stats)
      format_stat stats[AVG_FULL]
    end

    def min_load_style(stats)
      performance_style_class(stats, MIN_LOAD)
    end

    def min_normalization_style(stats)
      performance_style_class(stats, MIN_NORM)
    end

    def min_full_request_style(stats)
      performance_style_class(stats, MIN_FULL)
    end

    def max_load_style(stats)
      performance_style_class(stats, MAX_LOAD)
    end

    def max_normalization_style(stats)
      performance_style_class(stats, MAX_NORM)
    end

    def max_full_request_style(stats)
      performance_style_class(stats, MAX_FULL)
    end

    def avg_load_style(stats)
      performance_style_class(stats, AVG_LOAD)
    end

    def avg_normalization_style(stats)
      performance_style_class(stats, AVG_NORM)
    end

    def avg_full_request_style(stats)
      performance_style_class(stats, AVG_FULL)
    end

    private

      def all_authorities_performance_data
        performance_data[ALL_AUTH]
      end

      def format_stat(stat)
        format("%0.1f", stat)
      end

      def performance_style_class(stats, stat_key)
        return "status-bad" if max_threshold_exceeded(stats, stat_key)
        return "status-unknown" if min_threshold_not_met(stats, stat_key)
        "status-neutral"
      end

      MAX_THRESHOLD = 1000 # ms
      def max_threshold_exceeded(stats, stat_key)
        return true if stats[stat_key] > MAX_THRESHOLD
        false
      end

      MIN_THRESHOLD = 500 # ms
      def min_threshold_not_met(stats, stat_key)
        return true unless stats[stat_key] < MIN_THRESHOLD
        false
      end

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

      def graph_filename(authority_name, time_period)
        "performance_of_#{authority_name}_for_#{time_period}_graph.png"
      end

      def performance_for_day_graph_filename
        graph_filename(ALL_AUTH, :day)
      end

      def performance_for_day_graph_full_path
        graph_full_path(performance_for_day_graph_filename)
      end

      def performance_for_month_graph_filename
        graph_filename(ALL_AUTH, :month)
      end

      def performance_for_month_graph_full_path
        graph_full_path(performance_for_month_graph_filename)
      end

      def performance_for_year_graph_filename
        graph_filename(ALL_AUTH, :year)
      end

      def performance_for_year_graph_full_path
        graph_full_path(performance_for_year_graph_filename)
      end

      def rework_performance_data_for_gruff(performance_data, label_key)
        labels = {}
        load_data = []
        normalization_data = []
        full_request_data = []
        performance_data.each do |i, data|
          labels[i] = data[label_key]
          load_data << data[STATS][AVG_LOAD]
          normalization_data << data[STATS][AVG_NORM]
          full_request_data << data[STATS][AVG_FULL]
        end
        [labels, load_data, normalization_data, full_request_data]
      end

      def performance_graph_file(performance_data, performance_graph_full_path, performance_graph_filename, x_axis_label)
        g = Gruff::Line.new
        performance_graph_theme(g, x_axis_label)
        g.title = ''
        g.labels = performance_data[0]
        g.data(I18n.t('qa_server.monitor_status.performance.load_time_ms'), performance_data[1])
        g.data(I18n.t('qa_server.monitor_status.performance.normalization_time_ms'), performance_data[2])
        g.data(I18n.t('qa_server.monitor_status.performance.full_request_time_ms'), performance_data[3])
        g.write performance_graph_full_path
        File.join(graph_relative_path, performance_graph_filename)
      end
  end
end
