# This class loads an authority.
module QaServer
  class AuthorityLoaderService

    # Load a QA authority
    # @param authority_name [String] name of the authority to load (e.g. "agrovoc_direct")
    # @param status_log [ScenarioLogger] logger to hold failure information if the authority cannot be loaded
    # @return [Qa::Authorities::LinkedData::GenericAuthority] the instance of the authority that can receive QA requests OR nil if fails to load
    def self.load(authority_name:, status_log:)
      begin
        authority = load_authority(authority_name, status_log)
        return nil if authority.blank?
      rescue Exception => e
        status_log.add(authority_name: authority_name,
                       status: ScenarioValidator::FAIL,
                       error_message: "Unable to load authority '#{authority_name}'; cause: #{e.message}")
        return nil
      end
      authority
    end

    private
      def self.authority_key(authority_name)
        authority_name.upcase.to_sym
      end

      def self.load_authority(authority_name, status_log)
        authority = Qa::Authorities::LinkedData::GenericAuthority.new(authority_key(authority_name))
        if authority.blank?
          status_log.add(authority_name: authority_name,
                         status: ScenarioValidator::FAIL,
                         error_message: "Unable to load authority '#{authority_name}'; cause: UNKNOWN") unless authority.present?
          return nil
        end
        authority
    end
  end
end
