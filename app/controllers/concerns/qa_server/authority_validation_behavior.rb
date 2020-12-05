# frozen_string_literal: true
module QaServer
  module AuthorityValidationBehavior
    extend ActiveSupport::Concern

    VALIDATION_TYPE_PARAM = :validation_type
    VALIDATE_CONNECTIONS = 'connections'
    VALIDATE_ACCURACY = 'accuracy'
    VALIDATE_ACCURACY_COMPARISON = 'accuracy_comparison'
    ALL_VALIDATIONS = 'all_checks'

    included do
      class_attribute :validator_class,
                      :lister_class,
                      :logger_class

      self.validator_class = QaServer::AuthorityValidatorService
      self.lister_class = QaServer::AuthorityListerService
      self.logger_class = QaServer::ScenarioLogger
    end

    private

      def status_log
        @status_log ||= logger_class.new
      end

      def status_data_from_log
        @status_data = status_log.to_a
      end

      def authorities_list
        @authorities_list ||= lister_class.authorities_list
      end

      def validate(authorities_list, validation_type = validator_class::DEFAULT_VALIDATION_TYPE)
        return if authorities_list.blank?
        result = []
        authorities_list.each { |auth_name| result << validate_authority(auth_name, validation_type) }
        result
      end

      def validate_authority(auth_name, validation_type)
        validator_class.run(authority_name: auth_name, validation_type: validation_type, status_log: status_log)
      end

      def list(authorities_list)
        return if authorities_list.blank?
        authorities_list.each { |auth_name| list_scenarios(auth_name) }
      end

      def list_scenarios(auth_name)
        lister_class.scenarios_list(authority_name: auth_name, status_log: status_log)
      end

      def validating_accuracy?
        return true if validation_type == validator_class::VALIDATE_ACCURACY
        false
      end

      def comparing_accuracy?
        return true if validation_type == validator_class::VALIDATE_ACCURACY_COMPARISON
        false
      end

      def validation_type
        return @validation_type if @validation_type.present?
        case params[VALIDATION_TYPE_PARAM]
        when ALL_VALIDATIONS
          validator_class::ALL_VALIDATIONS
        when VALIDATE_CONNECTIONS
          validator_class::VALIDATE_CONNECTIONS
        when VALIDATE_ACCURACY
          validator_class::VALIDATE_ACCURACY
        when VALIDATE_ACCURACY_COMPARISON
          validator_class::VALIDATE_ACCURACY_COMPARISON
        else
          validator_class::DEFAULT_VALIDATION_TYPE
        end
      end
  end
end
