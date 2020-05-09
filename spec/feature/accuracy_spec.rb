# frozen_string_literal: true
require 'spec_helper'

# rubocop:disable RSpec/InstanceVariable
RSpec.describe 'Accuracy test' do # rubocop:disable RSpec/DescribeClass
  before(:all) { WebMock.allow_net_connect! }
  after(:all) { WebMock.disable_net_connect! }

  let(:authority_list) { QaServer::AuthorityListerService.authorities_list }
  let(:authority_name) { :CERL_LD4L_CACHE }

  describe 'for authority' do
    @status_log = QaServer::ScenarioLogger.new
    QaServer::AuthorityListerService.authorities_list.each do |authority_name| # rubocop:disable Style/MultilineIfModifier
      QaServer::AuthorityValidatorService.run(authority_name: authority_name,
                                              status_log: @status_log,
                                              validation_type: QaServer::ScenarioValidator::VALIDATE_ACCURACY)
    end unless ENV['TRAVIS']
    @status_log.each do |test_result|
      context "'#{test_result[:authority_name]}/#{test_result[:subauthority_name]}' with query '#{test_result[:request_data]}'" do
        it "finds a result" do
          expect(test_result[:actual]).not_to be_nil
        end

        it "finds actual <= expected" do
          expect(test_result[:actual]).to be <= test_result[:expected]
        end
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
