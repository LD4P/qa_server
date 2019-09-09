# frozen_string_literal: true
# This module provides methods for creating and accessing performance graphs.
module QaServer::MonitorStatus
  module PerformanceGraphBehavior
    include QaServer::PerformanceHistoryDataKeys
    include QaServer::MonitorStatus::GruffGraph

    def performance_graphs
      auth_list = QaServer::AuthorityListerService.authorities_list
      graphs = []
      performance_graphs_for_authority(graphs, ALL_AUTH)
      auth_list.each { |auth_name| performance_graphs_for_authority(graphs, auth_name) }
      graphs
    end

    def performance_graph(graph_info)
      graph_info[:graph]
    end

    def performance_graph_authority(graph_info)
      graph_info[:authority_name]
    end

    def performance_graph_label(graph_info)
      graph_info[:label]
    end

    def performance_default_graph_id
      "performance-for-day-#{ALL_AUTH}"
    end

    def performance_graph_id(graph_info)
      "#{graph_info[:base_id]}-during-#{graph_info[:time_period]}-chart"
    end

    def performance_graph_data_section_id(graph_info)
      "#{graph_info[:base_id]}-during-#{graph_info[:time_period]}"
    end

    def performance_graph_data_section_base_id(graph_info)
      graph_info[:base_id]
    end

    def performance_data_section_class(graph_info)
      return 'performance-data-section-visible' if default_graph?(graph_info)
      'performance-data-section-hidden'
    end

    def performance_day_graph_selected?(graph_info)
      return true if graph_info[:time_period] == :day
      false
    end

    def performance_month_graph_selected?(graph_info)
      return true if graph_info[:time_period] == :month
      false
    end

    def performance_year_graph_selected?(graph_info)
      return true if graph_info[:time_period] == :year
      false
    end

    private

      def default_graph?(graph_info)
        return true if QaServer.config.performance_graph_default_time_period == :day && performance_day_graph_selected?(graph_info)
        return true if QaServer.config.performance_graph_default_time_period == :month && performance_month_graph_selected?(graph_info)
        return true if QaServer.config.performance_graph_default_time_period == :year && performance_year_graph_selected?(graph_info)
        false
      end

      def performance_graphs_for_authority(graphs, auth_name)
        graphs << performance_for_day_graph(auth_name)
        graphs << performance_for_month_graph(auth_name)
        graphs << performance_for_year_graph(auth_name)
      end

      def performance_for_day_graph(auth_name)
        {
          time_period: :day,
          graph: QaServer::PerformanceGraphingService.performance_graph_file(authority_name: auth_name, time_period: :day),
          label: "Performance data for the last 24 hours.",
          authority_name: auth_name,
          base_id: "performance-for-#{auth_name}"
        }
      end

      def performance_for_month_graph(auth_name)
        {
          time_period: :month,
          graph: QaServer::PerformanceGraphingService.performance_graph_file(authority_name: auth_name, time_period: :month),
          label: "Performance data for the last 30 days.",
          authority_name: auth_name,
          base_id: "performance-for-#{auth_name}"
        }
      end

      def performance_for_year_graph(auth_name)
        {
          time_period: :year,
          graph: QaServer::PerformanceGraphingService.performance_graph_file(authority_name: auth_name, time_period: :year),
          label: "Performance data for the last 12 months.",
          authority_name: auth_name,
          base_id: "performance-for-#{auth_name}"
        }
      end
  end
end
