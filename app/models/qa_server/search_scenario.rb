# frozen_string_literal: true
# This class parses the search configuration from the yml file into the parts needed by the search scenario validator.
module QaServer
  class SearchScenario < AuthorityScenario
    # @return [String] query being executed by this scenario
    attr_reader :query

    # @return [Hash] replacements parameters used to construct the URL executed by this scenario
    attr_reader :replacements

    # @return [Integer] expected_by_position designates the maximum position in search results of subject_uri, if specified, for this scenario to be considered passing
    attr_reader :expected_by_position

    # @return [String] subject_uri, if specified, should be in the search results between position 1 and expected_by_position
    attr_reader :subject_uri

    MAX_RECORDS = '4'
    DEFAULT_REPLACEMENTS = { maxRecords: MAX_RECORDS }.freeze
    DEFAULT_POSITION = nil
    DEFAULT_SUBJECT_URI = nil

    # @param authority [Qa::Authorities::LinkedData::GenericAuthority] the instance of the QA authority
    # @param authority_name [Symbol] the name of the authority the scenario tests (e.g. :AGROVOC_DIRECT)
    # @param authority_scenario_config [Hash] configurations from the yml file that pertain to all scenarios regardless of type
    # @param scenario_config [Hash] configuration from the yml file that are specific to a search scenario
    def initialize(authority:, authority_name:, authority_scenario_config:, scenario_config:)
      super
      @query = scenario_config['query']
      @subauthority_name = scenario_config['subauth'] || DEFAULT_SUBAUTH
      @min_result_size = scenario_config['result_size'] || MIN_EXPECTED_SIZE
      @replacements = scenario_config['replacements'] || DEFAULT_REPLACEMENTS
      @expected_by_position = scenario_config['position'] || DEFAULT_POSITION
      @subject_uri = scenario_config['subject_uri'] || DEFAULT_SUBJECT_URI
    end

    # Generate an example URL that can be called in a browser or through curl
    # @return [String] the example URL
    def url
      subauth = "/#{subauthority_name}" if subauthority?
      context = context? ? '&context=true' : ''
      prefix = "#{QaServer::Engine.qa_engine_mount}/search/linked_data/#{authority_name.downcase}#{subauth}"
      "#{prefix}?q=#{query}#{url_replacements}#{context}"
    end

    private

      # Convert replacements hash into URL parameters
      def url_replacements
        return "&maxRecords=#{MAX_RECORDS}" unless replacements
        param_replacements = ""
        replacements.each { |k, v| param_replacements += "&#{k}=#{v}" }
        param_replacements
      end

      def subauthority?
        subauthority_name.present?
      end
  end
end
