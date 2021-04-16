# frozen_string_literal: true
# This class determines the state (e.g. fully_up, mostly_up, barely_up, down)of an authority during the last 30 days.
module QaServer
  class HistoryUpDownService
    NO_DATA             = :no_data
    FULLY_UP            = :fully_up
    MOSTLY_UP           = :mostly_up
    EXCESSIVE_TIMEOUTS  = :timeouts
    BARELY_UP           = :barely_up
    DOWN                = :down

    MOSTLY_UP_THRESHOLD = 0.95
    TIMEOUT_THRESHOLD   = 0.5

    class_attribute :authority_lister, :scenario_history_class, :time_service
    self.authority_lister = QaServer::AuthorityListerService
    self.scenario_history_class = QaServer::ScenarioRunHistory
    self.time_service = QaServer::TimeService

    def last_30_days
      data = {}
      authorities_list.each { |authority| data[authority] = last_30_days_for(authority.to_s) }
      data
    end

  private

    # @returns [Hash <Array<Hash>>] data for an authority for each of the last 30 days
    # @example
    #   { 'AGROVOC' = [
    #       :FULLY_UP,   # 0 - today
    #       :MOSTLY_UP,  # 1 - yesterday
    #       :MOSTLY_UP,  # 2 - two days ago
    #       :FULLY_UP,   # 3 - three days ago
    #       :DOWN,       # 4 - four days ago
    #       ...          # etc.
    #     ]
    #   }
    def last_30_days_for(authority)
      auth_data = []
      0.upto(29) { |offset| auth_data[offset] = day_status(authority, offset) }
      auth_data
    end

    # @returns [Symbol] status for a given day for an authority
    def day_status(authority, offset)
      day = offset_day(offset)
      good_count = count_good(authority, day)
      unknown_count = count_unknown(authority, day)
      bad_count = count_bad(authority, day)
      timeout_count = count_timeouts(authority, day)
      status_determination(good_count, unknown_count, bad_count, timeout_count)
    end

    def status_determination(good_count, unknown_count, bad_count, timeout_count) # rubocop:disable Metrics/CyclomaticComplexity
      total_count = good_count + unknown_count + bad_count
      return NO_DATA if total_count.zero?
      return FULLY_UP if good_count == total_count
      return DOWN if bad_count == total_count
      return BARELY_UP if unknown_count == total_count
      return EXCESSIVE_TIMEOUTS if (timeout_count.to_f / total_count) > TIMEOUT_THRESHOLD
      return MOSTLY_UP if (bad_count.to_f / total_count) < (1 - MOSTLY_UP_THRESHOLD)
      BARELY_UP
    end

    def authorities_list
      @authorities_list ||= authority_lister.authorities_list
    end

    def offset_day(offset)
      @today ||= time_service.current_time
      time_service.pretty_query_date(@today - offset.days)
    end

    def count_good(authority, day)
      scenario_history_class.where(authority_name: authority)
                            .where(date: day)
                            .where(status: :good)
                            .count(:id)
    end

    def count_unknown(authority, day)
      scenario_history_class.where(authority_name: authority)
                            .where(date: day)
                            .where(status: :unknown)
                            .count(:id)
    end

    def count_bad(authority, day)
      scenario_history_class.where(authority_name: authority)
                            .where(date: day)
                            .where(status: :bad)
                            .count(:id)
    end

    def count_timeouts(authority, day)
      scenario_history_class.where(authority_name: authority)
                            .where(date: day)
                            .where('err_message LIKE ?', "%timeout%")
                            .count(:id)
    end
  end
end
