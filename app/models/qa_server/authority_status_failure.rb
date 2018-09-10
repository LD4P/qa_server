# frozen_string_literal: true
# Provide access to the authority_status_failure database table which tracks specific failures over time.
module QaServer
  class AuthorityStatusFailure < ActiveRecord::Base
    self.table_name = 'authority_status_failure'
    belongs_to :authority_status
  end
end
