# frozen_string_literal: true
# This presenter class provides historical testing data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class HistoryPresenter
    CAUTION_THRESHOLD = 0.05
    WARNING_THRESHOLD = 0.1

    # @param parent [QaServer::MonitorStatusPresenter] parent presenter
    # @param historical_summary_data [Array<Hash>] summary of past failuring runs per authority to drive chart
    # @example historical_summary_data
    # {
    #   "AGROVOC_DIRECT"=>{:good=>4, :bad=>0},
    #   "AGROVOC_LD4L_CACHE"=>{:good=>4, :bad=>0}
    # }
    def initialize(parent:, historical_summary_data:)
      @parent = parent
      @historical_summary_data = historical_summary_data
    end

    # @return [Array<Hash>] historical test data to be displayed (authname, failing, passing)
    # @example
    # {
    #   "AGROVOC_DIRECT"=>{:good=>4, :bad=>0},
    #   "AGROVOC_LD4L_CACHE"=>{:good=>4, :bad=>0}
    # }
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

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [String] name of the authority (e.g. 'AUTH_NAME')
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def historical_data_authority_name(historical_entry)
      historical_entry[0]
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [Integer] number of days with passing tests (e.g. 949)
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def days_authority_passing(historical_entry)
      historical_entry[1][:good]
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [Integer] number of days with failing tests (e.g. 51)
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def days_authority_failing(historical_entry)
      historical_entry[1][:bad]
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [Integer] number of days tested (e.g. 1000)
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def days_authority_tested(historical_entry)
      days_authority_passing(historical_entry) + days_authority_failing(historical_entry)
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [Float] percent of failing to passing tests (e.g. 0.05374 )
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def percent_authority_failing(historical_entry)
      days_authority_failing(historical_entry).to_f / days_authority_tested(historical_entry)
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [String] percent of failing to passing tests (e.g. '5.4%')
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def percent_authority_failing_str(historical_entry)
      ActiveSupport::NumberHelper.number_to_percentage(percent_authority_failing(historical_entry) * 100, precision: 1)
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [String] css class for background in Days Failing and Percent Failing columns (e.g. 'status-neutral', 'status-unknown', 'status-bad')
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def failure_style_class(historical_entry)
      case percent_authority_failing(historical_entry)
      when 0.0...CAUTION_THRESHOLD
        "status-neutral"
      when CAUTION_THRESHOLD...WARNING_THRESHOLD
        "status-unknown"
      else
        "status-bad"
      end
    end

    # @param historical_entry [Array<String,Hash>] data for a single authority including name, # passing tests (good), # failing tests (bad)
    # @return [String] css class for background in Days Passing column (e.g. 'status-good', 'status-bad')
    # @example historical_entry
    #   [ 'AUTH_NAME',  { good: 949, bad: 51 } ]
    def passing_style_class(historical_entry)
      days_authority_passing(historical_entry) <= 0 ? "status-bad" : "status-good"
    end

    # @return [Boolean] true if historical section should be visible; otherwise false
    def display_history_details?
      display_historical_graph? || display_historical_datatable?
    end

    # @return [Boolean] true if historical graph should be visible; otherwise false
    def display_historical_graph?
      QaServer.config.display_historical_graph? && QaServer::HistoryGraphingService.history_graph_image_exists?
    end

    # @return [Boolean] true if historical datatable should be visible; otherwise false
    def display_historical_datatable?
      QaServer.config.display_historical_datatable?
    end
  end
end
