# frozen_string_literal: true
# Provide service methods for getting a list of all authorities and scenarios for an authority.
module QaServer
  class JobIdCache
    class << self
      # Is the passed in job_id the active one for the job_key?
      # @param job_key [String] key unique to the job being run (e.g. "QaServer::Jobs::MonitorTestsJob")
      # @param job_id [String] UUID for job running the tests
      # @param expires_in [ActiveSupport::Duration]  This should be at least as long as the expected job run time to avoid multiple instances of the job running at the same time.
      # @note When job completes, call reset_job_id to invalidate the cache
      def active_job_id?(job_key:, job_id:, expires_in: 30.minutes)
        cached_job_id = Rails.cache.fetch(cache_key(job_key), expires_in: expires_in, race_condition_ttl: 5.minutes) { job_id }
        cached_job_id == job_id
      end

      # Delete cache for job id for the job represented by job_key.  Call this when the job completes.
      # @param job_key [String] key unique to the job being run (e.g. "QaServer::Jobs::MonitorTestsJob")
      def reset_job_id(job_key:)
        Rails.cache.delete(cache_key(job_key))
      end

    private

      def cache_key(job_key)
        "#{job_key}-job_id"
      end
    end
  end
end
