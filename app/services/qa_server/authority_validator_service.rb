# frozen_string_literal: true
# Provide service methods for running a a set of validation scenarios for an authority.
module QaServer
  class AuthorityValidatorService
    class_attribute :validator_class,
                    :term_validator_class,
                    :search_validator_class,
                    :scenarios_loader_class

    self.validator_class = QaServer::ScenarioValidator
    self.term_validator_class = QaServer::TermScenarioValidator
    self.search_validator_class = QaServer::SearchScenarioValidator
    self.scenarios_loader_class = QaServer::ScenariosLoaderService

    VALIDATE_CONNECTIONS = validator_class::VALIDATE_CONNECTION
    VALIDATE_ACCURACY = validator_class::VALIDATE_ACCURACY
    VALIDATE_ACCURACY_COMPARISON = validator_class::VALIDATE_ACCURACY_COMPARISON
    ALL_VALIDATIONS = validator_class::ALL_VALIDATIONS
    DEFAULT_VALIDATION_TYPE = validator_class::DEFAULT_VALIDATION_TYPE

    # Run the set of validation scenarios for an authority logging the results
    # @param authority_name [String] the name of the authority
    # @param status_log [ScenarioLogger] the log that will hold the data about the scenarios and test results
    # @param validation_type [Symbol] the type of scenarios to run (e.g. VALIDATE_CONNECTIONS, VALIDATE_ACCURACY, ALL_VALIDATIONS)
    def self.run(authority_name:, status_log:, validation_type: DEFAULT_VALIDATION_TYPE)
      scenarios = scenarios_loader_class.load(authority_name: authority_name, status_log: status_log)
      return if scenarios.blank?
      run_terms(scenarios, status_log, validation_type)
      run_searches(scenarios, status_log, validation_type)
    end

    def self.run_terms(scenarios, status_log, validation_type)
      scenarios.term_scenarios.each { |scenario| term_validator_class.new(scenario: scenario, status_log: status_log, validation_type: validation_type).run }
    end
    private_class_method :run_terms

    def self.run_searches(scenarios, status_log, validation_type)
      scenarios.search_scenarios.each { |scenario| search_validator_class.new(scenario: scenario, status_log: status_log, validation_type: validation_type).run }
    end
    private_class_method :run_searches
  end
end
