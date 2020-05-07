# frozen_string_literal: true
# This presenter class provides performance data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class PerformancePresenter
    include QaServer::MonitorStatus::PerformanceDatatableBehavior
    include QaServer::MonitorStatus::PerformanceGraphBehavior
    include QaServer::PerformanceHistoryDataKeys

    # @param parent [QaServer::MonitorStatusPresenter] parent presenter
    # @param performance_data [Hash<Hash>] performance data
    def initialize(parent:, performance_data:)
      @parent = parent
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
      QaServer.config.display_performance_graph? && !performance_graphs.nil? && !performance_graphs.empty?
    end

    def display_performance_datatable?
      QaServer.config.display_performance_datatable? && !performance_data.nil?
    end

    def performance_data_authority_name(entry)
      entry.keys.first
    end
  end
end
