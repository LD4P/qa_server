# frozen_string_literal: true
# Helper methods for caching for monitoring status.
module QaServer
  class CacheExpiryService
    class << self
      # @return [Float] number of seconds until cache should expire
      def cache_expiry
        cache_expires_at - QaServer::TimeService.current_time
      end

      # @param key [String] cache key
      # @param force [Boolean] if true, forces cache to regenerate by returning true; otherwise, uses cache expiry to determine whether cache has expired
      # @return [Boolean] true if cache has expired or is being forced to expire
      def cache_expired?(key:, force:, next_expiry:)
        # will return true only if the full expiry has passed or force was requested
        force = Rails.cache.fetch(key, expires_in: 5.minutes, race_condition_ttl: 30.seconds, force: force) { true }
        # reset cache so it will next expired at expected time
        Rails.cache.fetch(key, expires_in: next_expiry, race_condition_ttl: 30.seconds, force: true) { false }
        force
      end

      private

        # @return [ActiveSupport::TimeWithZone] DateTime at which cache should expire
        def cache_expires_at
          offset = QaServer.config.hour_offset_to_expire_cache
          offset_time = QaServer::TimeService.current_time
          offset_time = offset_time.tomorrow unless (offset_time + 5.minutes).hour < offset
          offset_time.beginning_of_day + offset.hours - 5.minutes
        end
    end
  end
end
