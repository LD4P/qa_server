# frozen_string_literal: true
# Helper methods for caching for monitoring status.
module QaServer
  class MonitorCacheService
    class << self
      # @return [Float] number of seconds until cache should expire
      def cache_expiry
        monitoring_expires_at - QaServer::TimeService.current_time
      end

      private

        # @return [ActiveSupport::TimeWithZone] DateTime at which cache should expire
        def monitoring_expires_at
          offset = QaServer.config.hour_offset_to_expire_cache
          offset_time = QaServer::TimeService.current_time
          offset_time = offset_time.tomorrow unless (offset_time + 5.minutes).hour < offset
          offset_time.beginning_of_day + offset.hours - 5.minutes
        end
    end
  end
end
