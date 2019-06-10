# frozen_string_literal: true
# Abstract class that parses the authority configuration from the yml file into the parts needed by inheriting scenario types.
module QaServer
  class AuthorityScenario
    # @return [Qa::Authorities::LinkedData::GenericAuthority] authority instance the scenarios run against
    attr_reader :authority

    # @return [String] name of the authority the scenarios run against (e.g. 'agrovoc_direct')
    attr_reader :authority_name

    # @return [String] identifies the primary service provider (e.g. 'ld4l_cache', 'direct', etc.)
    attr_reader :service

    # @return [String] name of the subauthority the scenario runs against
    attr_reader :subauthority_name

    # @return [Integer] the minimum size of data that must be returned for the scenario to be considered passing
    attr_reader :min_result_size

    DEFAULT_SUBAUTH = nil
    MIN_EXPECTED_SIZE = 200

    # @param authority [Qa::Authorities::LinkedData::GenericAuthority] the instance of the QA authority
    # @param authoity_name [String] the name of the authority the scenario tests (e.g. "agrovoc_direct")
    # @param authority_scenario_config [Hash] configurations from the yml file that pertain to all scenarios regardless of type
    # @param scenario_config [Hash] configuration from the yml file that are specific to a type of scenario
    def initialize(authority:, authority_name:, authority_scenario_config:, scenario_config: nil)
      @authority = authority
      @authority_name = authority_name
      @service = authority_scenario_config['service']
      @context = authority_scenario_config.fetch('context', false)
      @subauthority_name = DEFAULT_SUBAUTH
      @min_result_size = MIN_EXPECTED_SIZE
    end

    def context?
      @context
    end
  end
end
