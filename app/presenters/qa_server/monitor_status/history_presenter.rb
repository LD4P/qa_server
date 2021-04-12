# frozen_string_literal: true
# This presenter class provides historical testing data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class HistoryPresenter
    CAUTION_THRESHOLD = 0.05
    WARNING_THRESHOLD = 0.1

    # @param parent [QaServer::MonitorStatusPresenter] parent presenter
    # @param historical_summary_data [Array<Hash>] summary of past failuring runs per authority to drive chart
    def initialize(parent:, historical_summary_data:)
      @parent = parent
      @historical_summary_data = historical_summary_data
    end

    # @return [Array<Hash>] historical test data to be displayed (authname, failing, passing)
    # @example
    #   [ [ 'agrovoc', 0, 24 ],
    #     [ 'geonames_ld4l_cache', 2, 22 ] ... ]
    def historical_summary
      @historical_summary_data
    end

    def historical_graph
      QaServer::HistoryGraphingService.history_graph_image_path
    end

    # @return [Boolean] true if historical test data exists; otherwise false
    def history?
      @historical_summary_data.present?
    end

    # Return the first date of data represented in the history graph and data table
    # @return [String] string version of date formatted with just date (e.g. "02/01/2020")
    def history_start
      start_dt = case QaServer.config.historical_datatable_default_time_period
                 when :month
                   history_end_dt - 1.month
                 when :year
                   history_end_dt - 1.year
                 else
                   @parent.first_updated_dt
                 end
      QaServer::TimeService.pretty_date(start_dt)
    end

    # Return the last date of data represented in the history graph and data table
    # @return [ActiveSupport::TimeWithZone] date time stamp
    def history_end_dt
      @parent.last_updated_dt
    end

    # Return the last date of data represented in the history graph and data table
    # @return [String] string version of date formatted with just date (e.g. "02/01/2020")
    def history_end
      QaServer::TimeService.pretty_date(history_end_dt)
    end

    # @return [String] the name of the css style class to use for the status cell based on the status of the scenario test.
    def status_style_class(status)
      "status-#{status[:status]}"
    end

    # @return [String] the marker to use for the status cell based on the status of the scenario test
    def status_label(status)
      case status[:status]
      when :good
        QaServer::ScenarioRunHistory::GOOD_MARKER
      when :bad
        QaServer::ScenarioRunHistory::BAD_MARKER
      when :unknown
        QaServer::ScenarioRunHistory::UNKNOWN_MARKER
      end
    end

    def historical_data_authority_name(historical_entry)
      historical_entry[0]
    end

    def days_authority_passing(historical_entry)
      historical_entry[1][:good]
    end

    def days_authority_failing(historical_entry)
      historical_entry[1][:bad]
    end

    def days_authority_tested(historical_entry)
      days_authority_passing(historical_entry) + days_authority_failing(historical_entry)
    end

    def percent_authority_failing(historical_entry)
      days_authority_failing(historical_entry).to_f / days_authority_tested(historical_entry)
    end

    def percent_authority_failing_str(historical_entry)
      ActiveSupport::NumberHelper.number_to_percentage(percent_authority_failing(historical_entry) * 100, precision: 1)
    end

    def failure_style_class(historical_entry)
      return "status-neutral" if days_authority_failing(historical_entry) <= CAUTION_THRESHOLD
      percent_authority_failing(historical_entry) < WARNING_THRESHOLD ? "status-unknown" : "status-bad"
    end

    def passing_style_class(historical_entry)
      days_authority_passing(historical_entry) <= 0 ? "status-bad" : "status-good"
    end

    def display_history_details?
      display_historical_graph? || display_historical_datatable?
    end

    def display_historical_graph?
      QaServer.config.display_historical_graph? && QaServer::HistoryGraphingService.history_graph_image_exists?
    end

    def display_historical_datatable?
      QaServer.config.display_historical_datatable?
    end
  end
end
