# frozen_string_literal: true
# This module provides methods for creating and accessing performance graphs.
module QaServer::MonitorStatus
  module PerformanceGraphBehavior # rubocop:disable Metrics/ModuleLength
    include QaServer::PerformanceHistoryDataKeys

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

    def performance_graph_time_period(graph_info)
      graph_info[:time_period]
    end

    def performance_graph_action(graph_info)
      graph_info[:action]
    end

    def performance_graph_id(graph_info)
      "#{graph_info[:base_id]}-#{performance_graph_action(graph_info)}-during-#{performance_graph_time_period(graph_info)}-chart"
    end

    def performance_graph_data_section_id(graph_info)
      "#{graph_info[:base_id]}-#{performance_graph_action(graph_info)}-during-#{performance_graph_time_period(graph_info)}"
    end

    def performance_graph_data_section_base_id(graph_info)
      graph_info[:base_id]
    end

    def performance_data_section_class(graph_info)
      return 'performance-data-section-visible' if default_graph?(graph_info)
      'performance-data-section-hidden'
    end

    def performance_day_graph?(graph_info)
      return true if performance_graph_time_period(graph_info) == :day
      false
    end

    def performance_month_graph?(graph_info)
      return true if performance_graph_time_period(graph_info) == :month
      false
    end

    def performance_year_graph?(graph_info)
      return true if performance_graph_time_period(graph_info) == :year
      false
    end

    def performance_all_actions_graph?(graph_info)
      return true if performance_graph_action(graph_info) == :all_actions
      false
    end

    def performance_search_graph?(graph_info)
      return true if performance_graph_action(graph_info) == :search
      false
    end

    def performance_fetch_graph?(graph_info)
      return true if performance_graph_action(graph_info) == :fetch
      false
    end

    private

      def default_graph?(graph_info) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return false unless performance_all_actions_graph?(graph_info)
        return true if QaServer.config.performance_graph_default_time_period == :day && performance_day_graph?(graph_info)
        return true if QaServer.config.performance_graph_default_time_period == :month && performance_month_graph?(graph_info)
        return true if QaServer.config.performance_graph_default_time_period == :year && performance_year_graph?(graph_info)
        false
      end

      def performance_graphs_for_authority(graphs, auth_name)
        [:search, :fetch, :all_actions].each do |action|
          day_graph = performance_for_day_graph(auth_name, action)
          month_graph = performance_for_month_graph(auth_name, action)
          year_graph = performance_for_year_graph(auth_name, action)
          add_graphs(graphs, day_graph, month_graph, year_graph)
        end
      end

      # only add the graphs if all 3 exist
      def add_graphs(graphs, day_graph, month_graph, year_graph)
        return unless day_graph[:exists] && month_graph[:exists] && year_graph[:exists]
        graphs << day_graph
        graphs << month_graph
        graphs << year_graph
      end

      def performance_for_day_graph(auth_name, action)
        filepath = QaServer::PerformanceGraphingService.performance_graph_image_path(authority_name: auth_name, action: action, time_period: :day)
        exists = QaServer::PerformanceGraphingService.performance_graph_image_exists?(authority_name: auth_name, action: action, time_period: :day)
        {
          action: action,
          time_period: :day,
          graph: filepath,
          exists: exists,
          label: "Performance data for the last 24 hours.",
          authority_name: auth_name,
          base_id: "performance-of-#{auth_name}"
        }
      end

      def performance_for_month_graph(auth_name, action)
        filepath = QaServer::PerformanceGraphingService.performance_graph_image_path(authority_name: auth_name, action: action, time_period: :month)
        exists = QaServer::PerformanceGraphingService.performance_graph_image_exists?(authority_name: auth_name, action: action, time_period: :month)
        {
          action: action,
          time_period: :month,
          graph: filepath,
          exists: exists,
          label: "Performance data for the last 30 days.",
          authority_name: auth_name,
          base_id: "performance-of-#{auth_name}"
        }
      end

      def performance_for_year_graph(auth_name, action)
        filepath = QaServer::PerformanceGraphingService.performance_graph_image_path(authority_name: auth_name, action: action, time_period: :year)
        exists = QaServer::PerformanceGraphingService.performance_graph_image_exists?(authority_name: auth_name, action: action, time_period: :year)
        {
          action: action,
          time_period: :year,
          graph: filepath,
          exists: exists,
          label: "Performance data for the last 12 months.",
          authority_name: auth_name,
          base_id: "performance-of-#{auth_name}"
        }
      end
  end
end
