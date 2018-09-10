# frozen_string_literal: true
# This presenter class provides all data needed by the view that monitors status of authorities.
module QaServer
  class MonitorStatusPresenter
    # @param authority_count [Integer] number of loaded authorities
    # @param authority_status [AuthorityStatus] summary status of the latest run of test scenarios
    # @param current_data [Array<Hash>] current set of failures for the latest test run, if any
    # @param historical_data [Array<Hash>] data for past failures
    def initialize(authority_count:, authority_status:, current_data:, historical_data:)
      @authority_count = authority_count
      @authority_status = authority_status
      @current_failures = current_data
      @history = historical_data
    end

    # @return [String] date of last test run
    def last_updated
      @authority_status.dt_stamp.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%y - %I:%M %p")
    end

    # @return [String] date of first recorded test run
    def first_updated
      QaServer::AuthorityStatus.first.dt_stamp.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%y - %I:%M %p")
    end

    # @return [Integer] number of loaded authorities
    def authorities_count
      @authority_count
    end

    # @return [Integer] number of authorities with failing tests in the latest test run
    def failing_authorities_count
      @current_failures.map { |f| f[:authority_name] }.uniq.count
    end

    # @return [String] css style class representing whether all tests passed or any failed
    def authorities_count_style
      failures? ? 'status-bad' : 'status-good'
    end

    # @return [Integer] number of tests in the latest test run
    def tests_count
      @authority_status.test_count
    end

    # @return [Integer] number of passing tests in the latest test run
    def passing_tests_count
      tests_count - failing_tests_count
    end

    # @return [Integer] number of failing tests in the latest test run
    def failing_tests_count
      @current_failures.count
    end

    # @return [String] css style class representing whether all tests passed or any failed
    def failing_tests_style
      failures? ? 'status-bad' : 'status-good'
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
      @current_failures
    end

    # @return [Boolean] true if failure data exists for the latest test run; otherwise false
    def failures?
      failing_tests_count.positive?
    end

    # @return [Array<Hash>] historical test data to be displayed
    # @example
    #   [ { days_failing: 1, authority_name: 'AGROVOC_DIRECT' },
    #     { days_failing: 3, authority_name: 'AGROVOC_LD4L_CACHE' },
    #     { days_failing: 0, authority_name: 'LOCNAMES_LD4L_CACHE' } ]
    def history
      # TODO: STUBED -- need to include history of past failures -- Question: How much data to save?
      # Want to answer questions like...
      #   * # of failing days out of # of days run
      #   * # type of failures... can't load authority vs. exception vs. no data returned
      #   * for a given authority, did all tests fail or just a few?
      #   * are tests failing for a particular subauthority?
      #   * are tests failing for a particular type (search vs. term)
      history = []
      entry = { days_failing: 3,
                authority_name: "FOO",
                subauthority_name: "bar",
                service: 'test',
                action: 'search' }
      history << entry
    end

    # @return [Boolean] true if historical test data exists; otherwise false
    def history?
      # TODO: STUBED -- need check for history data
      false
    end
  end
end
