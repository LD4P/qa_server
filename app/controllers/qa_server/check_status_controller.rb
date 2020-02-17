# frozen_string_literal: true
# Controller for Check Status header menu item
module QaServer
  class CheckStatusController < ApplicationController
    layout 'qa_server'

    include QaServer::AuthorityValidationBehavior

    ALL_AUTHORITIES = '__all__'

    class_attribute :presenter_class
    self.presenter_class = QaServer::CheckStatusPresenter

    # Sets up presenter with data to display in the UI
    def index
      log_header
      validate(authorities_to_validate, validation_type)
      @presenter = presenter_class.new(authorities_list: authorities_list,
                                       connection_status_data: connection_status_data_from_log,
                                       accuracy_status_data: accuracy_status_data_from_log)
    end

    private

      def connection_status_data_from_log
        status_log.filter(type: validator_class::VALIDATE_CONNECTIONS)
      end

      def accuracy_status_data_from_log
        status_log.filter(type: validator_class::VALIDATE_ACCURACY)
      end

      def authorities_to_validate
        return [] unless authority_name.present?
        authority_name == ALL_AUTHORITIES ? authorities_list : [authority_name]
      end

      def authority_name
        return @authority_name if @authority_name.present?
        @authority_name = params.key?(:authority) ? params[:authority].downcase : nil
      end

      def log_header
        QaServer.config.performance_cache_logger.debug("-------------------------------------  check status  ---------------------------------")
        QaServer.config.performance_cache_logger.debug("(#{self.class}##{__method__}) check status page request (authority_name # #{authority_name})")
      end
  end
end
