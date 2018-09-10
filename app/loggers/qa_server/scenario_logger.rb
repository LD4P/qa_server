# Provide a log of scenario data and test results
module QaServer
  class ScenarioLogger
    attr_reader :test_count, :failure_count

    PASS = QaServer::ScenarioValidator::PASS
    FAIL = QaServer::ScenarioValidator::FAIL
    UNKNOWN = QaServer::ScenarioValidator::UNKNOWN

    def initialize(test_count = 0, failure_count = 0)
      @log = []
      @test_count = test_count
      @failure_count = failure_count
    end

    # Add a scenario to the log
    # @param authority_name [String] name of the authority the scenario was run against
    # @param status [Symbol] indicating whether the scenario passed, failed, or has unknown status (see PASS, FAIL, UNKNOWN constants)
    # @param validation_type [Symbol] the type of validation this status data describes (e.g. :connection, :accuracy)
    # @param subauth [String] name of the subauthority the scenario was run against
    # @param service [String] identifies the primary service provider (e.g. 'ld4l_cache', 'direct', etc.)
    # @param action [String] type of scenario (i.e. 'term', 'search')
    # @param url [String] example url that was used to test a specific term fetch or search query
    # @param error_message [String] error message if scenario failed
    # @param expected [Integer] the expected result (e.g. min size of result OR max position of subject within results)
    # @param actual [Integer] the actual result (e.g. actual size of results OR actual position of subject within results)
    # @param target [String] the expected target that was validated (e.g. subject_uri for query, pref label for term fetch)
    def add(authority_name:, validation_type: '', status:, subauth: '', service: '', action: '', url: '', error_message: '', expected: nil, actual: nil, target: nil)
      @test_count += 1
      case status
        when PASS
          status_label = '√'
        when UNKNOWN
          status_label = '?'
          @failure_count += 1
        when FAIL
          status_label = 'X'
          @failure_count += 1
      end
      @log << { type: validation_type,
                status: status,
                status_label: status_label,
                authority_name: authority_name,
                subauthority_name: subauth,
                service: service,
                action: action,
                url: url,
                expected: expected,
                actual: actual,
                target: target,
                err_message: error_message }
    end

    # Delete from the log any tests that passed.
    def delete_passing
      @log.delete_if { |entry| entry[:status] == PASS }
    end

    # Append a log to this log.
    # @param [ScenarioLog] the log to append to this log
    def append(other)
      return unless other.present?
      @log += other.to_a
      @test_count += other.test_count
      @failure_count += other.failure_count
    end

    # @return selected scenario test results data as an array limited to the specified type or all scenarios if type is nil
    def filter(type: nil)
      return @log if type.blank?
      @log.select { |entry| entry[:type] == type }
    end

    # @return the scenario test results data as an array
    def to_a
      @log
    end

    # @return the number of scenarios recorded in the log
    def size
      to_a.size
    end
  end
end
