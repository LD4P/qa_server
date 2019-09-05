# frozen_string_literal: true
# This module provides methods for creating and accessing performance graphs.
module QaServer::MonitorStatus
  module PerformanceGraphBehavior
    include QaServer::PerformanceHistoryDataKeys
    include QaServer::MonitorStatus::GruffGraph

    def performance_for_day_graph
      create_gruff_graph(rework_performance_data_for_gruff(all_authorities_performance_data[FOR_DAY], BY_HOUR),
                         performance_for_day_graph_full_path,
                         I18n.t('qa_server.monitor_status.performance.x_axis_hour'))
      performance_graph_file(performance_for_day_graph_filename)
    end

    def performance_for_month_graph
      create_gruff_graph(rework_performance_data_for_gruff(all_authorities_performance_data[FOR_MONTH], BY_DAY),
                         performance_for_month_graph_full_path,
                         I18n.t('qa_server.monitor_status.performance.x_axis_day'))
      performance_graph_file(performance_for_month_graph_filename)
    end

    def performance_for_year_graph
      create_gruff_graph(rework_performance_data_for_gruff(all_authorities_performance_data[FOR_YEAR], BY_MONTH),
                         performance_for_year_graph_full_path,
                         I18n.t('qa_server.monitor_status.performance.x_axis_month'))
      performance_graph_file(performance_for_year_graph_filename)
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

      def create_gruff_graph(performance_data, performance_graph_full_path, x_axis_label)
        g = Gruff::Line.new
        performance_graph_theme(g, x_axis_label)
        g.title = ''
        g.labels = performance_data[0]
        g.data(I18n.t('qa_server.monitor_status.performance.load_time_ms'), performance_data[1])
        g.data(I18n.t('qa_server.monitor_status.performance.normalization_time_ms'), performance_data[2])
        g.data(I18n.t('qa_server.monitor_status.performance.full_request_time_ms'), performance_data[3])
        g.write performance_graph_full_path
      end

      def performance_graph_file(performance_graph_filename)
        File.join(graph_relative_path, performance_graph_filename)
      end
  end
end
