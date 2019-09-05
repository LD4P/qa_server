# frozen_string_literal: true
# This presenter class provides performance data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class PerformancePresenter
    include QaServer::MonitorStatus::GruffGraph
    include QaServer::MonitorStatus::PerformanceDatatableBehavior
    include QaServer::MonitorStatus::PerformanceGraphBehavior
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
  end
end
