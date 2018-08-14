require 'erb'

# This class parses the term configuration from the yml file into the parts needed by the term scenario validator.
module QaServer
  class TermScenario < AuthorityScenario
    include ERB::Util

    # @return [String] id or uri of the term being fetched by this scenario
    attr_reader :identifier

    # @param authority [Qa::Authorities::LinkedData::GenericAuthority] the instance of the QA authority
    # @param authoity_name [Symbol] the name of the authority the scenario tests (e.g. :AGROVOC_DIRECT)
    # @param authority_scenario_config [Hash] configurations from the yml file that pertain to all scenarios regardless of type
    # @param scenario_config [Hash] configuration from the yml file that are specific to a term scenario
    def initialize(authority:, authority_name:, authority_scenario_config:, scenario_config:)
      super
      @identifier = scenario_config['identifier']
      @subauthority_name = scenario_config['subauth'] || DEFAULT_SUBAUTH
      @min_result_size = scenario_config['min_result_size'] || MIN_EXPECTED_SIZE
    end

    # Generate an example URL that can be called in a browser or through curl
    # @return [String] the example URL
    def url
      subauth = "/#{subauthority_name}" if subauthority_name.present?
      prefix = "/qa/show/linked_data/#{authority_name.downcase}#{subauth}"
      "#{prefix}/#{url_identifier}"
    end

    private

      # Convert identifier into URL safe version with encoding if needed.
      def url_identifier
        return uri_encode(identifier) if encode?
        identifier
      end

      def subauthority?
        subauthority_name.present?
      end

      def encode?
        authority.auth_config.term.term_id_expects_uri?
      end

      def uri_encode(uri)
        url_encode(uri).gsub(".", "%2E")
      end
  end
end
