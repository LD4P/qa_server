# frozen_string_literal: true
# This presenter class provides historical testing data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class HistoryUpDownPresenter
    attr_reader :historical_up_down_data

    # @param parent [QaServer::MonitorStatusPresenter] parent presenter
    # @param historical_up_down_data [Hash<Array>] recent connection status of queries (typically last 30 days)
    # @example historical_up_down_data
    #   { 'AGROVOC' = [
    #       :FULLY_UP,   # 0 - today
    #       :MOSTLY_UP,  # 1 - yesterday
    #       :MOSTLY_UP,  # 2 - two days ago
    #       :FULLY_UP,   # 3 - three days ago
    #       :DOWN,       # 4 - four days ago
    #       ...          # etc.
    #     ],
    #     'CERL' = [ ... ]
    #   }
    def initialize(parent:, historical_up_down_data:)
      @parent = parent
      @historical_up_down_data = historical_up_down_data
    end
    
    # @param status [Symbol] :fully_up, :mostly_up, :timeouts, :barely_up, :down
    # @param day [Integer] retrieve the status for this day
    # @return [String] name of the css class for the status
    def historical_up_down_status_class(status, day) # rubocop:disable Metrics/CyclomaticComplexity
      case status[day]
      when :no_date then 'connection-no-date'
      when :fully_up then 'connection-fully-up'
      when :mostly_up then 'connection-mostly-up'
      when :timeouts then 'connection-timeouts'
      when :barely_up then 'connection-barely-up'
      when :down then 'connection-down'
      end
    end

    # @return [Boolean] true if historical datatable should be visible; otherwise false
    def display_historical_up_down?
      QaServer.config.display_historical_datatable? && @historical_up_down_data.present?
    end
  end
end
