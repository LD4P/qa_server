# frozen_string_literal: true
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
    # @param [Hash] status_info holding information to be logged
    # @option authority_name [String] name of the authority the scenario was run against
    # @option status [Symbol] indicating whether the scenario passed, failed, or has unknown status (see PASS, FAIL, UNKNOWN constants)
    # @option validation_type [Symbol] the type of validation this status data describes (e.g. :connection, :accuracy)
    # @option subauth [String] name of the subauthority the scenario was run against
    # @option service [String] identifies the primary service provider (e.g. 'ld4l_cache', 'direct', etc.)
    # @option action [String] type of scenario (i.e. 'term', 'search')
    # @option url [String] example url that was used to test a specific term fetch or search query
    # @option error_message [String] error message if scenario failed
    # @option expected [Integer] the expected result (e.g. min size of result OR max position of subject within results)
    # @option actual [Integer] the actual result (e.g. actual size of results OR actual position of subject within results)
    # @option target [String] the expected target that was validated (e.g. subject_uri for query, pref label for term fetch)
    # @option request_run_time [BigDecimal] the amount of time to retrieve data from the authority
    # @option normalization_run_time [BigDecimal] the amount of time to normalize the retrieved data into json
    def add(status_info) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
      @test_count += 1
      @failure_count += 1 unless status_info[:status] == PASS
      @log << { type: status_info[:validation_type] || '',
                status: status_info[:status] || '',
                authority_name: status_info[:authority_name] || '',
                subauthority_name: status_info[:subauth] || '',
                service: status_info[:service] || '',
                action: status_info[:action] || '',
                url: status_info[:url] || '',
                expected: status_info[:expected] || nil,
                actual: status_info[:actual] || nil,
                target: status_info[:target] || nil,
                err_message: status_info[:error_message] || '',
                request_run_time: status_info[:request_run_time] || nil,
                normalization_run_time: status_info[:normalization_run_time] || nil }
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
      @log.size
    end

    private

      def status_label(status)
        case status
        when PASS
          '√'
        when UNKNOWN
          @failure_count += 1
          '?'
        when FAIL
          @failure_count += 1
          'X'
        else
          ''
        end
      end
  end
end
