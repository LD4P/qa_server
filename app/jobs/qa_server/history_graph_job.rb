# frozen_string_literal: true
# Job to run monitoring tests
module QaServer
  class HistoryGraphJob < ApplicationJob
    queue_as :default

    class_attribute :graphing_service
    self.graphing_service = QaServer::HistoryGraphingService

    def perform(data:)
      # checking active_job_id? prevents race conditions for long running jobs
      generate_graph(data) if QaServer::JobIdCache.active_job_id?(job_key: job_key, job_id: job_id)
    end

    private

      def generate_graph(data)
        QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}-#{job_id}) - GENERATING historical summary graph")
        graphing_service.generate_graph(data)
        QaServer.config.monitor_logger.debug("(#{self.class}##{__method__}-#{job_id}) COMPLETED historical summary graph generation")
        QaServer::JobIdCache.reset_job_id(job_key: job_key)
      end

      def job_key
        "QaServer::HistoryGraphJob--job_id"
      end
  end
end
