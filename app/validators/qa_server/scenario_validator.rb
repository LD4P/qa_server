# frozen_string_literal: true
# ABSTRACT class providing common methods for running a scenario of any type.
module QaServer
  class ScenarioValidator
    PASS = :good
    FAIL = :bad
    UNKNOWN = :unknown

    VALIDATE_CONNECTION = :connection
    VALIDATE_ACCURACY = :accuracy
    ALL_VALIDATIONS = :all_validations
    DEFAULT_VALIDATION_TYPE = VALIDATE_CONNECTION

    attr_reader :status_log, :scenario, :validation_type

    # @param scenario [SearchScenario | TermScenario] the scenario to run
    # @param status_log [ScenarioLogger] logger for recording test results
    # @param validation_type [Symbol] the type of scenarios to run (e.g. VALIDATE_CONNECTION, VALIDATE_ACCURACY, ALL_VALIDATIONS)
    def initialize(scenario:, status_log:, validation_type: DEFAULT_VALIDATION_TYPE)
      @status_log = status_log
      @scenario = scenario
      @validation_type = validation_type
    end

    # Run a search scenario and log results.
    def run
      run_accuracy_scenario if accuracy_scenario? && validating_accuracy?
      run_connection_scenario if connection_scenario? && validating_connections?
    end

    # Log the structure of the scenario without running the scenario test.
    def log_without_running
      log
    end

    private

      # Log the structure of the scenario and status of a test run.
      # @param [Hash] status_info holding information to be logged
      # @see QaServer::ScenarioLogger
      def log(status_info = {})
        status_info[:authority_name] = authority_name
        status_info[:validation_type] = scenario_validation_type
        status_info[:subauth] = subauthority_name
        status_info[:service] = service
        status_info[:action] = action
        status_info[:url] = url
        status_log.add(status_info)
      end

      def run_accuracy_scenario
        # ABSTRACT - must be implemented by scenario validator for specific types
      end

      def run_connection_scenario
        # ABSTRACT - must be implemented by scenario validator for specific types
      end

      # Runs the test in the block passed by the specific scenario type.
      # @return [Symbol] :good (PASS) or :unknown (UNKNOWN) based on whether enough results were returned
      def test_connection(min_expected_size: MIN_EXPECTED_SIZE, scenario_type_name:)
        dt_start = Time.now.utc
        results = yield if block_given?
        dt_end = Time.now.utc
        actual_size = results.to_s.length
        status = actual_size > min_expected_size ? PASS : UNKNOWN
        errmsg = status == PASS ? '' : "#{scenario_type_name.capitalize} scenario unknown status; cause: Results actual size (#{actual_size} < expected size (#{min_expected_size})"
        log(status: status, errmsg: errmsg, normalization_run_time: (dt_end - dt_start)) # TODO: need to get run times from results
      rescue Exception => e
        dt_end = Time.now.utc
        log(status: FAIL, errmsg: "Exception executing #{scenario_type_name} scenario; cause: #{e.message}", request_run_time: (dt_end - dt_start))
      end

      def authority
        scenario.authority
      end

      def authority_name
        scenario.authority_name.upcase
      end

      def subauthority_name
        scenario.subauthority_name
      end

      def service
        scenario.service
      end

      def url
        scenario.url
      end

      def action
        # ABSTRACT - must be implemented by scenario validator for specific types
      end

      def scenario_validation_type
        return VALIDATE_CONNECTION if connection_scenario?
        return VALIDATE_ACCURACY if accuracy_scenario?
        nil
      end

      def validating_connections?
        return true if validation_type == VALIDATE_CONNECTION || validation_type == ALL_VALIDATIONS
        false
      end

      def validating_accuracy?
        return true if validation_type == VALIDATE_ACCURACY || validation_type == ALL_VALIDATIONS
        false
      end

      def accuracy_scenario?
        # ABSTRACT define in specific scenario type validator (i.e. QaServer::TermScenarioValidator, QaServer::SearchScenarioValidator)
        false
      end

      def connection_scenario?
        # ABSTRACT define in specific scenario type validator (i.e. QaServer::TermScenarioValidator, QaServer::SearchScenarioValidator)
        false
      end
  end
end
