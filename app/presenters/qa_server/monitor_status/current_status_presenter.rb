# frozen_string_literal: true
# This presenter class provides data related to last test run as needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class CurrentStatusPresenter
    # @param parent [QaServer::MonitorStatusPresenter] parent presenter
    # @param current_summary [ScenarioRunSummary] summary status of the latest run of test scenarios
    # @param current_data [Array<Hash>] current set of failures for the latest test run, if any
    def initialize(parent:, current_summary:, current_failure_data:)
      @parent = parent
      @current_summary = current_summary
      @current_failure_data = current_failure_data
    end

    # @return [ActiveSupport::TimeWithZone] date time stamp of last test run
    def last_updated_dt
      @current_summary.run_dt_stamp
    end

    # @return [String] date with time of last test run
    def last_updated
      QaServer::TimeService.pretty_time(last_updated_dt)
    end

    # @return [ActiveSupport::TimeWithZone] date time stamp of first recorded test run
    def first_updated_dt
      QaServer::ScenarioRunRegistry.first_run_dt
    end

    # @return [String] date with time of first recorded test run
    def first_updated
      QaServer::TimeService.pretty_time(first_updated_dt)
    end

    # @return [Integer] number of loaded authorities
    def authorities_count
      @current_summary.authority_count
    end

    # @return [Integer] number of authorities with failing tests in the latest test run
    def failing_authorities_count
      @current_failure_data.map { |f| f[:authority_name] }.uniq.count
    end

    # @return [String] css style class representing whether all tests passed or any failed
    def authorities_count_style
      failures? ? 'status-bad' : 'status-good'
    end

    # @return [Integer] number of tests in the latest test run
    def tests_count
      @current_summary.total_scenario_count
    end

    # @return [Integer] number of passing tests in the latest test run
    def passing_tests_count
      @current_summary.passing_scenario_count
    end

    # @return [Integer] number of failing tests in the latest test run
    def failing_tests_count
      @current_summary.failing_scenario_count
    end

    # @return [String] css style class representing whether all tests passed or any failed
    def failing_tests_style
      failures? ? 'summary-status-bad' : 'status-good'
    end

    # @return [Array<Hash>] A list of failures data in the latest test run, if any
    # @example
    #   [ { status: :FAIL,
    #       status_label: 'X',
    #       authority_name: 'LOCNAMES_LD4L_CACHE',
    #       subauthority_name: 'person',
    #       service: 'ld4l_cache',
    #       action: 'search',
    #       url: '/qa/search/linked_data/locnames_ld4l_cache/person?q=mark twain&maxRecords=4',
    #       err_message: 'Exception: Something went wrong.' }, ... ]
    def failures
      @current_failure_data
    end

    # @return [Boolean] true if failure data exists for the latest test run; otherwise false
    def failures?
      failing_tests_count.positive?
    end
  end
end
