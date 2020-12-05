# frozen_string_literal: true
# This class runs a single term scenario and logs the results.
module QaServer
  class TermScenarioValidator < ScenarioValidator
    TERM_ACTION = 'term'

    # CONCRETE Implementation: Return value of request_data
    attr_reader :request_data
    private :request_data

    # @param scenario [TermScenario] the scenario to run
    # @param status_log [ScenarioLogger] logger for recording test results
    # @param validation_type [Symbol] the type of scenarios to run (e.g. VALIDATE_CONNECTION, VALIDATE_ACCURACY, ALL_VALIDATIONS)
    def initialize(scenario:, status_log:, validation_type: DEFAULT_VALIDATION_TYPE)
      super
      @request_data = scenario.identifier
    end

  private

    # CONCRETE Implementation: Run a term scenario and log results.
    def run_connection_scenario
      test_connection(min_expected_size: scenario.min_result_size, scenario_type_name: 'term') do
        authority.find(scenario.identifier,
                       subauth: scenario.subauthority_name)
      end
    end

    # CONCRETE Implementation: Run a term scenario and log results.
    def run_accuracy_scenario
      # no accuracy scenarios defined for terms at this time
    end

    def action
      TERM_ACTION
    end

    def accuracy_scenario?
      # At this time, all scenarios are connection scenarios for terms.
      false
    end

    def connection_scenario?
      # At this time, all scenarios are connection scenarios for terms.
      true
    end
  end
end
