# frozen_string_literal: true
# This presenter class provides all data needed by the view that checks the status of authorities.
module QaServer
  class CheckStatusPresenter
    # @param authorities_list [Array<String>] a list of all loaded authorities' names
    # @param status_data [Array<Hash>] a list of status data for each scenario tested
    def initialize(authorities_list:, connection_status_data:, accuracy_status_data:)
      @authorities_list = authorities_list
      @connection_status_data = connection_status_data
      @accuracy_status_data = accuracy_status_data
    end

    # @return [Array<String>] A list of all loaded authorities' names
    # @example ['AGROVOC_DIRECT', 'AGROVOC_LD4L_CACHE', 'LOCNAMES_LD4L_CACHE']
    attr_reader :authorities_list

    # rubocop:disable Style/AsciiComments
    # @return [Array<Hash>] A list of status data for each connection scenario tested.
    # @example
    #   [ { status: :PASS,
    #       status_label: '√',
    #       authority_name: 'LOCNAMES_LD4L_CACHE',
    #       subauthority_name: 'person',
    #       service: 'ld4l_cache',
    #       action: 'search',
    #       url: '/qa/search/linked_data/locnames_ld4l_cache/person?q=mark twain&maxRecords=4',
    #       err_message: '' }, ... ]
    attr_reader :connection_status_data
    # rubocop:enable Style/AsciiComments

    # rubocop:disable Style/AsciiComments
    # @return [Array<Hash>] A list of status data for each accuracy scenario tested.
    # @example
    #   [ { status: :PASS,
    #       status_label: '√',
    #       authority_name: 'LOCNAMES_LD4L_CACHE',
    #       subauthority_name: 'person',
    #       service: 'ld4l_cache',
    #       action: 'search',
    #       expected: 10,
    #       actual: 8,
    #       url: '/qa/search/linked_data/locnames_ld4l_cache/person?q=mark twain&maxRecords=20',
    #       err_message: '' }, ... ]
    attr_reader :accuracy_status_data
    # rubocop:enable Style/AsciiComments

    # @return [Boolean] true if status data exists; otherwise false
    def connection_status_data?
      @connection_status_data.present?
    end

    # @return [Boolean] true if status data exists; otherwise false
    def accuracy_status_data?
      @accuracy_status_data.present?
    end

    # @return [String] the name of the css style class to use for the status cell based on the status of the scenario test.
    def status_style_class(status)
      "status-#{status[:status]}"
    end

    # @return [String] the name of the css style class to use for the status cell based on the status of the scenario test.
    def status_label(status)
      case status[:status]
      when :good
        QaServer::ScenarioRunHistory::GOOD_MARKER
      when :bad
        QaServer::ScenarioRunHistory::BAD_MARKER
      when :unknown
        QaServer::ScenarioRunHistory::UNKNOWN_MARKER
      end
    end

    def value_all_collections
      QaServer::CheckStatusController::ALL_AUTHORITIES
    end

    def value_check_param
      QaServer::AuthorityValidationBehavior::VALIDATION_TYPE_PARAM
    end

    def value_check_connections
      QaServer::AuthorityValidationBehavior::VALIDATE_CONNECTIONS
    end

    def label_check_connections
      "#{value_check_param}_#{value_check_connections}".downcase.to_sym
    end

    def value_check_accuracy
      QaServer::AuthorityValidationBehavior::VALIDATE_ACCURACY
    end

    def label_check_accuracy
      "#{value_check_param}_#{value_check_accuracy}".downcase.to_sym
    end

    def value_all_checks
      QaServer::AuthorityValidationBehavior::ALL_VALIDATIONS
    end

    def label_all_checks
      "#{value_check_param}_#{value_all_checks}".downcase.to_sym
    end
  end
end
