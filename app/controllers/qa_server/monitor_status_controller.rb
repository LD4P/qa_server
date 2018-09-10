# frozen_string_literal: true
# Controller for Monitor Status header menu item
module QaServer
  class MonitorStatusController < QaServer::AuthorityValidationController
    class_attribute :presenter_class,
                    :authority_status_model_class,
                    :authority_status_failure_model_class

    self.presenter_class = QaServer::MonitorStatusPresenter
    self.authority_status_model_class = QaServer::AuthorityStatus
    self.authority_status_failure_model_class = QaServer::AuthorityStatusFailure

    # Sets up presenter with data to display in the UI
    def index
      authority_status = latest_authority_status
      if refresh? || expired_status? || authority_status.blank?
        validate(authorities_list)
        status_log.delete_passing
        update_authority_status
        authority_status = latest_authority_status
      end
      @authority_count = authorities_list.size
      # TODO: Include historical data too
      @presenter = presenter_class.new(authority_count: @authority_count,
                                       authority_status: @latest_authority_status,
                                       current_data: @status_data,
                                       historical_data: [])
      render 'index', status: :internal_server_error if authority_status.failure_count.positive?
    end

    private

      def latest_authority_status
        @status_data ||= authority_status_model_class.latest_failures.to_a
        @latest_authority_status ||= authority_status_model_class.latest
      end

      def update_authority_status
        save_authority_status(status_log)
        @status_data = status_data_from_log
      end

      def save_authority_status(status_log)
        @latest_authority_status = authority_status_model_class.create(dt_stamp: dt_stamp_now_et,
                                                                       test_count: status_log.test_count,
                                                                       failure_count: status_log.failure_count)
        status_log.to_a.each { |failure| save_authority_status_failure(@latest_authority_status, failure) }
      end

      def save_authority_status_failure(authority_status, failure)
        authority_status_failure_model_class.create(authority_status_id: authority_status.id,
                                                    status: failure[:status],
                                                    status_label: failure[:status_label],
                                                    authority_name: failure[:authority_name].to_s,
                                                    subauthority_name: failure[:subauthority_name],
                                                    service: failure[:service],
                                                    action: failure[:action],
                                                    url: failure[:url],
                                                    err_message: failure[:err_message])
      end

      def expired_status?
        status = latest_authority_status
        status.blank? || status.dt_stamp < yesterday_midnight_et
      end

      def yesterday_midnight_et
        (DateTime.yesterday.midnight.to_time + 4.hours).to_datetime.in_time_zone("Eastern Time (US & Canada)")
      end

      def dt_stamp_now_et
        Time.now.in_time_zone("Eastern Time (US & Canada)")
      end

      def refresh?
        params.key? :refresh
      end
  end
end
