# frozen_string_literal: true
# This class sets creates the performance graphs for each authority during day, month, and year time periods for fetch and search actions.
module QaServer
  class PerformanceGraphingService
    class << self
      include QaServer::PerformanceHistoryDataKeys
      include QaServer::GruffGraph

      class_attribute :authority_list_class
      self.authority_list_class = QaServer::AuthorityListerService

      # @param authority_name [String] name of the authority
      # @param action [Symbol] action performed by the request (e.g. :search, :fetch, :all_actions)
      # @param time_period [Symbol] time period for the graph (i.e. :day, :month, :year)
      # @return [String] Path to use with <image> tags
      def performance_graph_image_path(authority_name: ALL_AUTH, action:, time_period:)
        File.join(graph_image_path, graph_filename(authority_name, action, time_period))
      end
      alias performance_graph_file performance_graph_image_path

      # @param authority_name [String] name of the authority
      # @param action [Symbol] action performed by the request (e.g. :search, :fetch, :all_actions)
      # @param time_period [Symbol] time period for the graph (i.e. :day, :month, :year)
      # @return [Boolean] true if image for graph exists; otherwise, false
      def performance_graph_image_exists?(authority_name: ALL_AUTH, action:, time_period:)
        File.exist?(performance_graph_full_path(authority_name, action, time_period))
      end

      # Generate one 12 month graph for the authority and action given the graph data.
      # @param authority_name [String] name of the authority
      # @param action [Symbol] action performed by the request (e.g. :search, :fetch, :all_actions)
      # @param data [Hash] data to use to generate the graph
      # @see QaServer::PerformanceGraphDataService.calculate_last_12_months
      def generate_year_graph(authority_name: ALL_AUTH, action:, data:)
        gruff_data = rework_performance_data_for_gruff(data, BY_MONTH)
        create_gruff_graph(gruff_data,
                           performance_graph_full_path(authority_name, action, FOR_YEAR),
                           I18n.t('qa_server.monitor_status.performance.x_axis_month'))
        log_failure(authority_name, action, BY_MONTH)
      end

      # Generate one 30 day graph for the authority and action given the graph data.
      # @param authority_name [String] name of the authority
      # @param action [Symbol] action performed by the request (e.g. :search, :fetch, :all_actions)
      # @param data [Hash] data to use to generate the graph
      # @see QaServer::PerformanceGraphDataService.calculate_last_30_days
      def generate_daily_graph(authority_name: ALL_AUTH, action:, data:)
        gruff_data = rework_performance_data_for_gruff(data, BY_DAY)
        create_gruff_graph(gruff_data,
                           performance_graph_full_path(authority_name, action, FOR_MONTH),
                           I18n.t('qa_server.monitor_status.performance.x_axis_day'))
      end

      # Generate one 24 hour graph for the authority and action given the graph data.
      # @param authority_name [String] name of the authority
      # @param action [Symbol] action performed by the request (e.g. :search, :fetch, :all_actions)
      # @param data [Hash] data to use to generate the graph
      # @see QaServer::PerformanceGraphDataService.calculate_last_24_hours
      def generate_hourly_graph(authority_name: ALL_AUTH, action:, data:)
        gruff_data = rework_performance_data_for_gruff(data, BY_HOUR)
        create_gruff_graph(gruff_data,
                           performance_graph_full_path(authority_name, action, FOR_DAY),
                           I18n.t('qa_server.monitor_status.performance.x_axis_hour'))
      end

      private

        def performance_graph_full_path(authority_name, action, time_period)
          graph_full_path(graph_filename(authority_name, action, time_period))
        end

        def graph_filename(authority_name, action, time_period)
          "performance_of_#{authority_name}_#{action}_for_#{time_period}_graph.png"
        end

        def rework_performance_data_for_gruff(performance_data, label_key)
          labels = {}
          # full_load_data = []
          retrieve_data = []
          graph_load_data = []
          normalization_data = []
          performance_data.each do |i, data|
            labels[i] = data[label_key]
            retrieve_data << data[STATS][AVG_RETR]
            graph_load_data << graph_load_time(data)
            normalization_data << data[STATS][AVG_NORM]
          end
          [labels, retrieve_data, graph_load_data, normalization_data]
        end

        def graph_load_time(data)
          # For some sense of backward compatibility and to avoid losing the usefulness of previously collected data,
          # create the graph using the old :load stat when both :retrieve and :graph_load are 0. If the value truly
          # is 0, then :load will also be 0.
          # NOTE: It's ok to use AVG_RETR for the retrieve data point because it is 0.
          # rubocop:disable Style/TernaryParentheses
          (data[STATS][AVG_RETR].zero? && data[STATS][AVG_GRPH].zero?) ? data[STATS][AVG_LOAD] : data[STATS][AVG_GRPH]
          # rubocop:enable Style/TernaryParentheses
        end

        def performance_graph_theme(g, x_axis_label)
          g.theme_pastel
          g.colors = [QaServer.config.performance_normalization_color,
                      QaServer.config.performance_graph_load_color,
                      QaServer.config.performance_retrieve_color]
          g.marker_font_size = 12
          g.x_axis_increment = 10
          g.x_axis_label = x_axis_label
          g.y_axis_label = I18n.t('qa_server.monitor_status.performance.y_axis_ms')
          g.minimum_value = 0
          g.maximum_value = QaServer.config.performance_y_axis_max
        end

        def create_gruff_graph(performance_data, performance_graph_full_path, x_axis_label)
          g = Gruff::StackedBar.new
          performance_graph_theme(g, x_axis_label)
          g.labels = performance_data[0]
          g.data(I18n.t('qa_server.monitor_status.performance.retrieve_time_ms'), performance_data[1])
          g.data(I18n.t('qa_server.monitor_status.performance.graph_load_time_ms'), performance_data[2])
          g.data(I18n.t('qa_server.monitor_status.performance.normalization_time_ms'), performance_data[3])
          g.write performance_graph_full_path
        end

        def log_failure(authority_name, action, time_period)
          relative_path = performance_graph_image_path(authority_name: authority_name, action: action, time_period: time_period)
          exists = performance_graph_image_exists?(authority_name: authority_name, action: action, time_period: time_period)
          QaServer.config.monitor_logger.warn("FAILED to write performance graph at #{relative_path}") unless exists
        end
    end
  end
end
