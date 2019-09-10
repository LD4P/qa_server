# frozen_string_literal: true
# This class sets creates the performance graphs for each authority during day, month, and year time periods for fetch and search actions.
module QaServer
  class PerformanceGraphingService
    class << self
      include QaServer::PerformanceHistoryDataKeys
      include QaServer::MonitorStatus::GruffGraph

      class_attribute :authority_list_class
      self.authority_list_class = QaServer::AuthorityListerService

      # @param performance_data [Hash] hash of all performance data for all authorities
      # @see QaServer:PerformanceHistory
      def create_performance_graphs(performance_data:)
        performance_data.each_key { |auth_name| create_graphs_for_authority(performance_data, auth_name.to_sym) }
      end

      # @param authority_name [String] name of the authority
      # @param time_period [Symbol] time period for the graph (i.e. :day, :month, :year)
      def performance_graph_file(authority_name: ALL_AUTH, time_period:)
        File.join(graph_relative_path, graph_filename(authority_name, time_period))
      end

      private

        def create_graphs_for_authority(performance_data, authority_name)
          create_performance_for_day_graph(performance_data, authority_name)
          create_performance_for_month_graph(performance_data, authority_name)
          create_performance_for_year_graph(performance_data, authority_name)
        end

        def create_performance_for_day_graph(performance_data, authority_name)
          auth_data = authority_performance_data(performance_data, authority_name)
          return unless auth_data
          gruff_data = rework_performance_data_for_gruff(auth_data[FOR_DAY], BY_HOUR)
          create_gruff_graph(gruff_data,
                             performance_for_day_graph_full_path(authority_name),
                             I18n.t('qa_server.monitor_status.performance.x_axis_hour'))
        end

        def create_performance_for_month_graph(performance_data, authority_name)
          auth_data = authority_performance_data(performance_data, authority_name)
          gruff_data = rework_performance_data_for_gruff(auth_data[FOR_MONTH], BY_DAY)
          create_gruff_graph(gruff_data,
                             performance_for_month_graph_full_path(authority_name),
                             I18n.t('qa_server.monitor_status.performance.x_axis_day'))
        end

        def create_performance_for_year_graph(performance_data, authority_name)
          auth_data = authority_performance_data(performance_data, authority_name)
          gruff_data = rework_performance_data_for_gruff(auth_data[FOR_YEAR], BY_MONTH)
          create_gruff_graph(gruff_data,
                             performance_for_year_graph_full_path(authority_name),
                             I18n.t('qa_server.monitor_status.performance.x_axis_month'))
        end

        def authority_performance_data(data, authority_name)
          auth_name = authority_name.nil? ? ALL_AUTH : authority_name
          data[auth_name]
        end

        def performance_graph_theme(g, x_axis_label)
          g.theme_pastel
          g.colors = [QaServer.config.performance_normalization_color,
                      QaServer.config.performance_load_color]
          g.marker_font_size = 12
          g.x_axis_increment = 10
          g.x_axis_label = x_axis_label
          g.y_axis_label = I18n.t('qa_server.monitor_status.performance.y_axis_ms')
          g.minimum_value = 0
          g.maximum_value = 2000
        end

        def performance_for_day_graph_full_path(authority_name)
          graph_full_path(graph_filename(authority_name, :day))
        end

        def performance_for_month_graph_full_path(authority_name)
          graph_full_path(graph_filename(authority_name, :month))
        end

        def performance_for_year_graph_full_path(authority_name)
          graph_full_path(graph_filename(authority_name, :year))
        end

        def graph_filename(authority_name, time_period)
          "performance_of_#{authority_name}_for_#{time_period}_graph.png"
        end

        def rework_performance_data_for_gruff(performance_data, label_key)
          labels = {}
          load_data = []
          normalization_data = []
          performance_data.each do |i, data|
            labels[i] = data[label_key]
            load_data << data[STATS][AVG_LOAD]
            normalization_data << data[STATS][AVG_NORM]
          end
          [labels, normalization_data, load_data]
        end

        def create_gruff_graph(performance_data, performance_graph_full_path, x_axis_label)
          g = Gruff::StackedBar.new
          performance_graph_theme(g, x_axis_label)
          g.title = ''
          g.labels = performance_data[0]
          g.data(I18n.t('qa_server.monitor_status.performance.normalization_time_ms'), performance_data[1])
          g.data(I18n.t('qa_server.monitor_status.performance.load_time_ms'), performance_data[2])
          g.write performance_graph_full_path
        end
    end
  end
end
