# Holds all scenarios for an authority.
module QaServer
  class Scenarios

    AUTHORITY_SCENARIO = 'authority'.freeze
    TERM_SCENARIOS = 'term'.freeze
    SEARCH_SCENARIOS = 'search'.freeze

    # @return [Qa::Authorities::LinkedData::GenericAuthority] authority instance the scenarios run against
    attr_reader :authority

    # @return [String] name of the authority the scenarios run against (e.g. 'agrovoc_direct')
    attr_reader :authority_name

    # @return [Array<TermScenario>] the term scenarios to run against the authority
    attr_reader :term_scenarios

    # @return [Array<SearchScenario>] the search scenarios to run against the authority
    attr_reader :search_scenarios

    # @param authority [Qa::Authorities::LinkedData::GenericAuthority] the instance of the QA authority
    # @param authoity_name [String] the name of the authority the scenario tests (e.g. "agrovoc_direct")
    # @param scenarios_config [Hash] configurations from the yml file for all scenarios for an authority
    def initialize(authority:, authority_name:, scenarios_config:)
      @authority = authority
      @authority_name = authority_name
      @scenarios_config = scenarios_config
      parse_term_scenarios
      parse_search_scenarios
    end

    private

      def parse_term_scenarios
        @term_scenarios = []
        term_scenarios_config.each do |term_scenario_config|
          @term_scenarios << QaServer::TermScenario.new(authority: authority,
                                                        authority_name: authority_name,
                                                        authority_scenario_config: authority_scenario_config,
                                                        scenario_config: term_scenario_config)
        end
      end

      def parse_search_scenarios
        @search_scenarios = []
        search_scenarios_config.each do |search_scenario_config|
          @search_scenarios << QaServer::SearchScenario.new(authority: authority,
                                                            authority_name: authority_name,
                                                            authority_scenario_config: authority_scenario_config,
                                                            scenario_config: search_scenario_config)
        end
      end

      def scenarios_config
        @scenarios_config
      end

      def authority_scenario_config
        scenarios_config[AUTHORITY_SCENARIO]
      end

      def term_scenarios_config
        scenarios_config[TERM_SCENARIOS] || []
      end

      def search_scenarios_config
        scenarios_config[SEARCH_SCENARIOS] || []
      end
  end
end
