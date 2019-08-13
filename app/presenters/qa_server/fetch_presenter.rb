# frozen_string_literal: true
# This presenter class provides all data needed by the view that checks the status of authorities.

require 'json'

module QaServer
  class FetchPresenter
    # @param authorities_list [Array<String>] a list of all loaded authorities' names
    # @param authority [String] name of the authority from which the term was fetched (e.g. 'LOCSUBJECT_LD4L_CACHE')
    # @param uri [String] requested URI (e.g. 'http://id.loc.gov/authorities/subjects/sh2003008312')
    # @param format [String] return results in this format (e.g. 'json', 'jsonld', 'n3')
    # @param term_results [String] results of fetching a term in the requested format
    def initialize(authorities_list:, authority: nil, uri: nil, format: nil, term_results: nil)
      @authorities_list = authorities_list.map(&:upcase)
      @authority = authority.present? ? authority.upcase : nil
      @uri = uri
      @format = format
      @term_results = term_results
    end

    # @return [Array<String>] A list of all loaded authorities' names
    # @example ['AGROVOC_DIRECT', 'AGROVOC_LD4L_CACHE', 'LOCNAMES_LD4L_CACHE']
    attr_reader :authorities_list

    # @return [String] Name of authority that was searched
    # @example 'AGROVOC_LD4L_CACHE'
    attr_reader :authority

    # @return [String] The requested URI
    # @example 'http://id.loc.gov/authorities/subjects/sh2003008312'
    attr_reader :uri

    # @return [Array<String>] list of supported formats
    def formats_list
      ['json', 'jsonld', 'n3']
    end

    # @return [String] format for the returned results of fetching the term
    # @example 'json', 'jsonld', 'n3'
    attr_reader :format

    def json?
      format.casecmp? 'json'
    end

    def jsonld?
      format.casecmp? 'jsonld'
    end

    def n3?
      format.casecmp? 'n3'
    end

    # @return [String] results for the term fetch in the requested format
    def term_results
      return JSON.pretty_generate(@term_results) if json?
      @term_results
    end

    # @return [Boolean] true if search results exist; otherwise false
    def term_results?
      @term_results.present?
    end
  end
end
