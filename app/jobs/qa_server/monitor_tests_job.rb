# frozen_string_literal: true
# Job to run monitoring tests
module QaServer
  class MonitorTestsJob < ApplicationJob
    include QaServer::AuthorityValidationBehavior

    queue_as :default

    class_attribute :scenario_run_registry_class
    self.scenario_run_registry_class = QaServer::ScenarioRunRegistry

    # def perform(job_id:)
    def perform
      Rails.cache.fetch("QaServer::MonitorTestsController/latest_run", expires_in: QaServer::MonitorCacheService.cache_expiry, race_condition_ttl: 5.minutes, force: true) do
        job_id = SecureRandom.uuid
        monitor_tests_job_id = job_id unless monitor_tests_job_id
        if monitor_tests_job_id == job_id # avoid race conditions
          QaServer.config.monitor_logger.info("(#{self.class}##{__method__}-#{job_id}) RUNNING monitoring tests")
          validate(authorities_list)
          scenario_run_registry_class.save_run(scenarios_results: status_log.to_a)
          QaServer.config.monitor_logger.info("(#{self.class}##{__method__}-#{job_id}) COMPLETED monitoring tests")
          reset_monitor_tests_job_id
        end
        scenario_run_registry_class.latest_run
      end
    end

    private

      # @return [String, Boolean] Returns job id of the job currently running tests; otherwise, false if tests are not running
      def monitor_tests_job_id
        Rails.cache.fetch("QaServer:monitor_tests-job_id", expires_in: 2.hours, race_condition_ttl: 1.hour) { false }
      end

      # Set the id of the job that will run the tests.
      # @param job_id [String] UUID for job running the tests
      def monitor_tests_job_id=(job_id)
        # check to see if there is a current job already running tests
        current_job_id = Rails.cache.fetch("QaServer:monitor_tests-job_id", expires_in: 2.hours, race_condition_ttl: 30.seconds) { job_id }

        # current_job_id may be false meaning tests are not currently running; in which case, it is ok to force set job_id
        Rails.cache.fetch("QaServer:monitor_tests-job_id", expires_in: 2.hours, race_condition_ttl: 30.seconds, force: true) { job_id } unless current_job_id
      end

      # Set job id for monitor tests to false indicating that tests are not currently running
      def reset_monitor_tests_job_id
        Rails.cache.fetch("QaServer:monitor_tests-job_id", expires_in: 2.hours, race_condition_ttl: 1.hour, force: true) { false }
      end
  end
end
