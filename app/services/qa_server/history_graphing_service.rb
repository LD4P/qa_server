# frozen_string_literal: true
# This class sets creates the performance graphs for each authority during day, month, and year time periods for fetch and search actions.
module QaServer
  class HistoryGraphingService
    class << self
      include QaServer::MonitorStatus::GruffGraph

      HISTORICAL_GRAPH_FILENAME = 'historical_side_stacked_bar.png'

      class_attribute :authority_list_class
      self.authority_list_class = QaServer::AuthorityListerService

      # Path to use with <image> tags
      def history_graph_image_path
        historical_graph_relative_path
      end

      # @return [Boolean] true if image for graph exists; otherwise, false
      def history_graph_image_exists?
        File.exist? historical_graph_full_path
      end

      # Generate the graph of historical data
      # @param data [Hash] data to use to generate the graph
      # @see QaServer::ScenarioHistoricalCache.historical_summary for source of data
      def generate_graph(data)
        gruff_data = rework_historical_data_for_gruff(data)
        create_gruff_graph(gruff_data, historical_graph_full_path)
        QaServer.config.monitor_logger.warn("FAILED to write historical graph at #{history_graph_image_path}") unless history_graph_image_exists?
      end

      private

        def create_gruff_graph(reworked_data, full_path)
          g = Gruff::SideStackedBar.new
          historical_graph_theme(g)
          g.labels = reworked_data[0]
          g.data('Fail', reworked_data[1])
          g.data('Pass', reworked_data[2])
          g.write full_path
        end

        def historical_graph_theme(g)
          g.theme_pastel
          g.colors = ['#ffcccc', '#ccffcc']
          g.marker_font_size = 12
          g.x_axis_increment = 10
        end

        def historical_graph_full_path
          graph_full_path(HISTORICAL_GRAPH_FILENAME)
        end

        def historical_graph_relative_path
          File.join(graph_relative_path, HISTORICAL_GRAPH_FILENAME)
        end

        def rework_historical_data_for_gruff(data)
          labels = {}
          pass_data = []
          fail_data = []
          i = 0
          data.each do |authname, authdata|
            labels[i] = authname
            i += 1
            fail_data << authdata[:bad]
            pass_data << authdata[:good]
          end
          [labels, fail_data, pass_data]
        end
    end
  end
end
