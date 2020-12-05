# frozen_string_literal: true
# Controller for Check Status header menu item
module QaServer
  class CheckStatusController < ApplicationController
    layout 'qa_server'

    include QaServer::AuthorityValidationBehavior

    ALL_AUTHORITIES = '__all__'
    VALIDATE_ACCURACY_COMPARISON = :accuracy_comparison

    class_attribute :presenter_class
    self.presenter_class = QaServer::CheckStatusPresenter

    # Sets up presenter with data to display in the UI
    def index
      log_header
      validate(authorities_to_validate, validation_type)
      @presenter = presenter_class.new(authorities_list: authorities_list,
                                       connection_status_data: connection_status_data_from_log,
                                       accuracy_status_data: accuracy_status_data_from_log,
                                       comparison_status_data: comparison_status_data_from_log)
    end

    private

      def connection_status_data_from_log
        status_log.filter(type: validator_class::VALIDATE_CONNECTIONS)
      end

      def accuracy_status_data_from_log
        return [] unless validating_accuracy?
        status_log.filter(type: validator_class::VALIDATE_ACCURACY)
      end

      def comparison_status_data_from_log
        return [] unless comparing_accuracy?
        filtered_log = status_log.filter(type: validator_class::VALIDATE_ACCURACY, group: true)
        return [] unless filtered_log.count == 2
        overlay_log(filtered_log)
      end

      def overlay_log(log)
        auths = log.keys
        auth_a = log[auths[0]]
        auth_b = log[auths[1]]
        overlay = []
        auth_a.each { |test| overlay << match_and_merge_test(test, auth_b) }
        auth_b.each { |test| overlay << merge_test_results(empty_test(test), test) }
        overlay
      end

      def match_and_merge_test(a_test, auth_b)
        auth_b.each_with_index do |b_test, idx|
          next unless b_test[:action] == a_test[:action]
          next unless b_test[:subauthority_name] == a_test[:subauthority_name]
          next unless b_test[:request_data] == a_test[:request_data]
          next unless b_test[:target] == a_test[:target]
          return merge_test_results(a_test, auth_b.delete_at(idx))
        end
        merge_test_results(a_test, empty_test(a_test))
      end

      def merge_test_results(a_test, b_test)
        merged_tests = {}
        merged_tests[:status] = [a_test[:status], b_test[:status]]
        merged_tests[:service] = [a_test[:service], b_test[:service]]
        merged_tests[:action] = a_test[:action]
        merged_tests[:authority_name] = [a_test[:authority_name], b_test[:authority_name]]
        merged_tests[:subauthority_name] = a_test[:subauthority_name]
        merged_tests[:request_data] = a_test[:request_data]
        merged_tests[:target] = a_test[:target]
        merged_tests[:expected] = [a_test[:expected], b_test[:expected]]
        merged_tests[:actual] = [a_test[:actual], b_test[:actual]]
        merged_tests[:url] = [a_test[:url], b_test[:url]]
        merged_tests[:err_message] = [a_test[:err_message], b_test[:err_message]]
        merged_tests
      end

      def empty_test(base_test)
        merged_tests = {}
        merged_tests[:status] = ''
        merged_tests[:service] = ''
        merged_tests[:action] = base_test[:action]
        merged_tests[:authority_name] = ''
        merged_tests[:subauthority_name] = base_test[:subauthority_name]
        merged_tests[:request_data] = base_test[:request_data]
        merged_tests[:target] = base_test[:target]
        merged_tests[:expected] = ''
        merged_tests[:actual] = ''
        merged_tests[:url] = ''
        merged_tests[:err_message] = ''
        merged_tests
      end

      def authorities_to_validate
        return [] if authority_name.blank?
        authority_names = authority_name == ALL_AUTHORITIES ? authorities_list : [authority_name]
        authority_names << compare_with if compare_with.present?
        authority_names
      end

      def authority_name
        return @authority_name if @authority_name.present?
        @authority_name = params.key?(:authority) ? params[:authority].downcase : nil
      end

      def compare_with
        return @compare_with if @compare_with.present?
        @compare_with = params.key?(:compare_with) ? params[:compare_with].downcase : nil
      end

      def log_header
        QaServer.config.performance_cache_logger.debug("----------------------  check status (max_cache_size = #{max_cache_size}) ----------------------")
        QaServer.config.performance_cache_logger.debug("(#{self.class}##{__method__}) check status page request (authority_name # #{authority_name})")
      end

      def max_cache_size
        ActiveSupport::NumberHelper.number_to_human_size(QaServer.config.max_performance_cache_size)
      end
  end
end
