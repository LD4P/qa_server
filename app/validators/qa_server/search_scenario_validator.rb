# frozen_string_literal: true
require 'json'

# This class runs a single search scenario and logs the results.
module QaServer
  class SearchScenarioValidator < ScenarioValidator
    SEARCH_ACTION = 'search'

    # CONCRETE Implementation: Return value of request_data
    attr_reader :request_data
    private :request_data

    # @param scenario [SearchScenario] the scenario to run
    # @param status_log [ScenarioLogger] logger for recording test results
    # @param validation_type [Symbol] the type of scenarios to run (e.g. VALIDATE_CONNECTION, VALIDATE_ACCURACY, ALL_VALIDATIONS)
    def initialize(scenario:, status_log:, validation_type: DEFAULT_VALIDATION_TYPE)
      super
      @request_data = scenario.query
    end

    private

      def action
        SEARCH_ACTION
      end

      # CONCRETE Implementation: Run the connection test and log results
      def run_connection_scenario
        test_connection(min_expected_size: scenario.min_result_size, scenario_type_name: 'search') do
          replacements = scenario.replacements.dup
          authority.search(scenario.query,
                           subauth: scenario.subauthority_name,
                           replacements: replacements)
        end
      end

      # CONCRETE Implementation: Run the accuracy test and log results
      def run_accuracy_scenario
        test_accuracy(subject_uri: scenario.subject_uri, expected_by_position: scenario.expected_by_position) do
          replacements = scenario.replacements.dup
          authority.search(scenario.query,
                           subauth: scenario.subauthority_name,
                           replacements: replacements)
        end
      end

      # Runs the accuracy test and log results
      def test_accuracy(subject_uri:, expected_by_position:)
        dt_start = QaServer::TimeService.current_time
        results = yield if block_given?
        dt_end = QaServer::TimeService.current_time
        if results.blank?
          log(status: UNKNOWN, errmsg: "Search position scenario failed; cause: no results found", expected: expected_by_position, target: subject_uri, request_run_time: (dt_end - dt_start))
          return
        end

        check_position(results, subject_uri, expected_by_position, total_run_time: (dt_end - dt_start)) # TODO: need to get run times from results
      rescue Exception => e
        dt_end = QaServer::TimeService.current_time
        log(status: FAIL, errmsg: "Exception executing search position scenario; cause: #{e.message}",
            expected: expected_by_position, target: subject_uri, request_run_time: (dt_end - dt_start))
      end

      def accuracy_scenario?
        return false if scenario.expected_by_position.blank? || scenario.subject_uri.blank?
        true
      end

      def connection_scenario?
        # There are only two types of tests, so if this isn't an accuracy scenario, it must be a connection scenario.
        !accuracy_scenario?
      end

      def check_position(results, subject_uri, expected_by_position, total_run_time)
        actual_position = subject_position(results, subject_uri, total_run_time)
        return if actual_position.blank?

        actual_position += 1
        if actual_position <= expected_by_position
          log(status: PASS, expected: expected_by_position, actual: actual_position, target: subject_uri,
              normalization_run_time: total_run_time) # TODO: need to get run times from results
        else
          log(status: UNKNOWN, errmsg: 'Subject URI not found by the expected position.',
              expected: expected_by_position, actual: actual_position, target: subject_uri,
              normalization_run_time: total_run_time) # TODO: need to get run times from results
        end
      end

      def subject_position(results, subject_uri, total_run_time)
        0.upto(results.size - 1) do |position|
          return position if results[position][:uri] == subject_uri
        end
        log(status: UNKNOWN, errmsg: "Search position scenario failed; cause: subject uri (#{subject_uri}) not found in results",
            expected: scenario.expected_by_position, target: subject_uri, normalization_run_time: total_run_time) # TODO: need to get run times from results
        nil
      end
  end
end
