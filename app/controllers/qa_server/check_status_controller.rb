# Controller for Check Status header menu item
module QaServer
  class CheckStatusController < AuthorityValidationController

    ALL_AUTHORITIES = '__all__'.freeze

    class_attribute :presenter_class
    self.presenter_class = CheckStatusPresenter

    # Sets up presenter with data to display in the UI
    def index
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
        (authority_name == ALL_AUTHORITIES) ? authorities_list : [authority_name]
      end

      def authority_name
        return @authority_name if @authority_name.present?
        @authority_name = (params.key? :authority) ? params[:authority].downcase : nil
      end
  end
end
