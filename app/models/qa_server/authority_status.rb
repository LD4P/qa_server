# Provide access to the authority_status database table which tracks a summary of status data over time.
module QaServer
  class AuthorityStatus < ActiveRecord::Base
    self.table_name = 'authority_status'
    has_many :authority_status_failure, foreign_key: :authority_status_id

    # Get the latest saved status.
    def self.latest
      last
    end

    # Get the latest set of failures, if any.
    def self.latest_failures
      return nil if latest.blank?
      AuthorityStatusFailure.where(authority_status_id: latest.id)
    end
  end
end
