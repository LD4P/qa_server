# frozen_string_literal: true
# Create where clauses for time periods and authorities.
module QaServer
  class TimePeriodService
    class << self
      # Construct a hash to pass to ActiveRecord where method limiting to last 24 hours and optionally an authority.
      # @param auth_name [String] authority name if limiting to an authority; otherwise, nil
      # @param auth_table [Symbol] name of the table holding the authority name; or nil if in same table
      # @param dt_table [Symbol] name of the table holding the date-time stamp; or nil if in same table
      # @return [Hash] a where clause for the last 24 hours for an authority
      # @example returned where for join
      #   { scenario_run_registry: { dt_stamp: start_hour..end_hour },
      #     scenario_run_history: { authority: 'LOC_DIRECT' } }
      # @example returned where for join with no authority
      #   { scenario_run_registry: { dt_stamp: start_hour..end_hour } }
      # @example returned where for same table
      #   { dt_stamp: start_hour..end_hour, authority: 'LOC_DIRECT' }
      # @example returned where when no authority
      #   { dt_stamp: start_hour..end_hour }
      def where_clause_for_last_24_hours(auth_name: nil, auth_table: nil, dt_table: nil)
        validate_params(auth_name, auth_table, dt_table)
        where_clause = where_for_dt_stamp(dt_table, 1.day)
        where_with_authority(where_clause, auth_name, auth_table)
      end

      # Construct a hash to pass to ActiveRecord where method limiting to last 30 days and optionally an authority.
      # @param auth_name [String] authority name if limiting to an authority; otherwise, nil
      # @param auth_table [Symbol] name of the table holding the authority name; or nil if in same table
      # @param dt_table [Symbol] name of the table holding the date-time stamp; or nil if in same table
      # @return [Hash] a where clause for the last 30 days for an authority
      # @example returned where for join
      #   { scenario_run_registry: { dt_stamp: start_day..end_day },
      #     scenario_run_history: { authority: 'LOC_DIRECT' } }
      # @example returned where for join with no authority
      #   { scenario_run_registry: { dt_stamp: start_day..end_day } }
      # @example returned where for same table
      #   { dt_stamp: start_day..end_day, authority: 'LOC_DIRECT' }
      # @example returned where when no authority
      #   { dt_stamp: start_day..end_day }
      def where_clause_for_last_30_days(auth_name: nil, auth_table: nil, dt_table: nil)
        validate_params(auth_name, auth_table, dt_table)
        where_clause = where_for_dt_stamp(dt_table, 1.month)
        where_with_authority(where_clause, auth_name, auth_table)
      end

      # Construct a hash to pass to ActiveRecord where method limiting to last 12 months and optionally an authority.
      # @param auth_name [String] authority name if limiting to an authority; otherwise, nil
      # @param auth_table [Symbol] name of the table holding the authority name; or nil if in same table
      # @param dt_table [Symbol] name of the table holding the date-time stamp; or nil if in same table
      # @return [Hash] a where clause for the last 12 months for an authority
      # @example returned where for join
      #   { scenario_run_registry: { dt_stamp: start_month..end_month },
      #     scenario_run_history: { authority: 'LOC_DIRECT' } }
      # @example returned where for join with no authority
      #   { scenario_run_registry: { dt_stamp: start_month..end_month } }
      # @example returned where for same table
      #   { dt_stamp: start_month..end_month, authority: 'LOC_DIRECT' }
      # @example returned where when no authority
      #   { dt_stamp: start_month..end_month }
      def where_clause_for_last_12_months(auth_name: nil, auth_table: nil, dt_table: nil)
        validate_params(auth_name, auth_table, dt_table)
        where_clause = where_for_dt_stamp(dt_table, 1.year)
        where_with_authority(where_clause, auth_name, auth_table)
      end

      private

        def where_for_dt_stamp(dt_table, time_period)
          end_range = QaServer::TimeService.current_time
          start_range = end_range - time_period
          where_clause = { dt_stamp: start_range..end_range }
          where_clause = { dt_table => where_clause } unless dt_table.nil?
          where_clause
        end

        def where_with_authority(where_clause, auth_name, auth_table)
          return where_clause if auth_name.nil?
          if auth_table.nil?
            where_clause[:authority] = auth_name
          else
            where_clause[auth_table] = { authority: auth_name }
          end
          where_clause
        end

        def validate_params(auth_name, auth_table, dt_table)
          raise ArgumentError, "Do not specify auth_table when auth_name is not specified" if auth_table.present? && auth_name.nil?
          return if auth_name.nil?
          raise ArgumentError, "Either both table names need to be specified or neither" if auth_table.present? ^ dt_table.present?
        end
    end
  end
end
