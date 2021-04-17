# frozen_string_literal: true
# Create where clauses for time periods and authorities.
module QaServer
  class TimeService
    class << self
      # @return [ActiveSupport::TimeWithZone] current DateTime in the configured preferred_time_zone_name
      def current_time
        Time.now.in_time_zone(QaServer.config.preferred_time_zone_name)
      end

      # @return [Float] current DateTime in seconds
      def current_time_s
        current_time.to_f
      end

      # @param dt [ActiveSupport::TimeWithZone] date time stamp
      # @return [String] string version of date formatted with date and time (e.g. "02/01/2020 - 02:35 PM ET")
      def pretty_time(dt)
        dt.in_time_zone(QaServer.config.preferred_time_zone_name).strftime("%m/%d/%Y - %I:%M %p")
      end

      # @param dt [ActiveSupport::TimeWithZone] date time stamp
      # @return [String] string version of date formatted with just date (e.g. "02/01/2020")
      def pretty_date(dt)
        dt.in_time_zone(QaServer.config.preferred_time_zone_name).strftime("%m/%d/%Y")
      end

      # @param dt [ActiveSupport::TimeWithZone] date time stamp
      # @return [String] string version of date formatted with just date (e.g. "2020-02-01")
      def pretty_query_date(dt)
        dt.in_time_zone(QaServer.config.preferred_time_zone_name).strftime("%Y-%m-%d")
      end
    end
  end
end
