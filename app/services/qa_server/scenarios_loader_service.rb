# This class loads scenario configuration file for an authority.
module QaServer
  class ScenariosLoaderService

    # Load scenarios for testing an authority
    # @param authority_name [String] name of the authority to load (e.g. "agrovoc_direct")
    # @param status_log [ScenarioLogger] logger to hold failure information if the scenarios cannot be loaded
    # @return [Scenarios] the instance of the set of scenarios to test for the authority OR nil if fails to load
    def self.load(authority_name:, status_log:)
      begin
        authority = load_authority(authority_name, status_log)
        return nil if authority.blank?
        return nil unless scenarios_exist?(authority_name, status_log)

        scenarios_config = load_config(authority_name, status_log)
        return nil if scenarios_config.blank?

        scenarios = QaServer::Scenarios.new(authority: authority, authority_name: authority_name, scenarios_config: scenarios_config)
      rescue Exception => e
        status_log.add(authority_name: authority_name,
                       status: QaServer::ScenarioValidator::FAIL,
                       error_message: "Unable to load scenarios for authority '#{authority_name}'; cause: #{e.message}")
        return nil
      end
      scenarios
    end

    private

      def self.load_authority(authority_name, status_log)
        QaServer::AuthorityLoaderService.load(authority_name: authority_name, status_log: status_log)
      end

      def self.load_config(authority_name, status_log)
        scenarios_config = YAML.load_file(scenario_path(authority_name))
        unless scenarios_config.present?
          status_log.add(authority_name: authority_name,
                         status: QaServer::ScenarioValidator::FAIL,
                         error_message: "Unable to load scenarios for authority '#{authority_name}'; cause: UNKNOWN")
          return nil
        end
        scenarios_config
      end

      def self.scenarios_exist?(authority_name, status_log)
        return true if File.exists?(scenario_path(authority_name))
        status_log.add(authority_name: authority_name,
                       status: QaServer::ScenarioValidator::FAIL,
                       error_message: "Unable to load scenarios for authority '#{authority_name}'; cause: #{scenario_path} does not exist.")
        false
      end

      def self.scenario_path(authority_name)
        File.join(::Rails.root, 'config', 'authorities', 'linked_data', 'scenarios', "#{authority_name.downcase}_validation.yml")
      end
  end
end
