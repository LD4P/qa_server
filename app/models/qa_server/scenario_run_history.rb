# Provide access to the scenario_results_history database table which tracks specific scenario runs over time.
module QaServer
  class ScenarioRunHistory < ActiveRecord::Base
    self.table_name = 'scenario_run_history'
    belongs_to :scenario_run_registry
    enum scenario_type: [:connection, :accuracy, :performance], _suffix: :type
    enum status: [:good, :bad, :unknown], _suffix: true

    GOOD_MARKER = '√'.freeze
    BAD_MARKER = 'X'.freeze
    UNKNOWN_MARKER = '?'.freeze

    class_attribute :summary_class

    self.summary_class = QaServer::ScenarioRunSummary

    # Save a scenario result
    # @param run_id [Integer] the run on which to gather statistics
    # @param result [Hash] the scenario result to be saved
    def self.save_result(run_id:, scenario_result:)
      QaServer::ScenarioRunHistory.create(scenario_run_registry_id: run_id,
                                          status: scenario_result[:status],
                                          authority_name: scenario_result[:authority_name],
                                          subauthority_name: scenario_result[:subauthority_name],
                                          service: scenario_result[:service],
                                          action: scenario_result[:action],
                                          url: scenario_result[:url],
                                          err_message: scenario_result[:err_message],
                                          run_time: scenario_result[:run_time])
    end

    # Get a summary of passing/failing tests for a run.
    # @param scenario_run [ScenarioRunRegistry] the run on which to gather statistics
    # @returns [Hash] statistics on the requested run
    # @example
    #   { run_id: 14,
    #     failing_count: 3,
    #     passing_count: 156,
    #     total_count: 159,
    #     authority_count: 22,
    #     failing_authority_count: 1 }
    def self.run_summary(scenario_run:)
      return nil unless scenario_run && scenario_run.id
      status = status_counts_in_run(run_id: scenario_run.id)
      summary_class.new(run_id: scenario_run.id,
                        run_dt_stamp: scenario_run.dt_stamp,
                        authority_count: authorities_in_run(run_id: scenario_run.id).count,
                        failing_authority_count: authorities_with_failures_in_run(run_id: scenario_run.id).count,
                        passing_scenario_count: status['good'],
                        failing_scenario_count: status['bad'] + status['unknown'])
    end

    # Get set of all scenario results for a run.
    # @param run_id [Integer] the run on which to gather statistics
    # @param authority_name [String] limit results to those for the authority with this name
    # @param status [Array<Symbol> | Symbol] :good, :bad, :unknown, or any of these in an array to select multiple status
    # @param url [String] limit results to a specific scenario URL
    # @returns [Array<ScenarioRunHistory>] scenario details for all scenarios in the run
    # @example
    #   [ { status: :bad,
    #       authority_name: "geonames_ld4l_cache",
    #       subauthority_name: "area",
    #       service: "ld4l_cache",
    #       action: "search",
    #       url: "/qa/search/linked_data/geonames_ld4l_cache/area?q=France&maxRecords=4",
    #       err_message: "Unable to connect to authority",
    #       scenario_type: :connection
    #       run_time: 11.2 },
    #     { status: :good,
    #       authority_name: "oclcfast_ld4l_cache",
    #       subauthority_name: "Organization",
    #       service: "ld4l_cache",
    #       action: "search",
    #       url: "/qa/search/linked_data/oclcfast_ld4l_cache/organization?q=mark twain&maxRecords=4",
    #       err_message: "",
    #       scenario_type: :connection
    #       run_time: 0.131 },
    #     { status: :unknown,
    #       authority_name: "oclcfast_ld4l_cache",
    #       subauthority_name: "Person",
    #       service: "ld4l_cache",
    #       action: "search",
    #       url: "/qa/search/linked_data/oclcfast_ld4l_cache/person?q=mark twain&maxRecords=4",
    #       err_message: "Not enough search results returned",
    #       scenario_type: :connection
    #       run_time: 0.123 } ]
    def self.run_results(run_id:, authority_name: nil, status: nil, url: nil)
      return [] unless run_id
      where = {}
      where[:scenario_run_registry_id] = run_id
      where[:authority_name] = authority_name if authority_name.present?
      where[:status] = status if status.present?
      where[:url] = url if url.present?
      QaServer::ScenarioRunHistory.where(where).to_a
    end

    # Get set of failures for a run, if any.
    # @param run_id [Integer] the run on which to gather statistics
    # @returns [Array<Hash>] scenario details for any failing scenarios in the run
    # @example
    #   [ { status: :bad,
    #       authority_name: "geonames_ld4l_cache",
    #       subauthority_name: "area",
    #       service: "ld4l_cache",
    #       action: "search",
    #       url: "/qa/search/linked_data/geonames_ld4l_cache/area?q=France&maxRecords=4",
    #       err_message: "Unable to connect to authority",
    #       scenario_type: :connection
    #       run_time: 11.2 },
    #     { status: :unknown,
    #       authority_name: "oclcfast_ld4l_cache",
    #       subauthority_name: "Person",
    #       service: "ld4l_cache",
    #       action: "search",
    #       url: "/qa/search/linked_data/oclcfast_ld4l_cache/person?q=mark twain&maxRecords=4",
    #       err_message: "Not enough search results returned",
    #       scenario_type: :connection
    #       run_time: 0.123 } ]
    def self.run_failures(run_id:)
      return [] unless run_id
      QaServer::ScenarioRunHistory.where(scenario_run_registry_id: run_id).where.not(status: :good).to_a
    end

    # Get a summary level of historical data
    # @returns [Array<Hash>] scenario details for any failing scenarios in the run
    # @example
    #   [ [ 'agrovoc', 24, 0 ],
    #     [ 'geonames_ld4l_cache', 24, 2 ] ... ]
    def self.historical_summary
      runs = all_runs_per_authority
      failures = failing_runs_per_authority
      return [] unless runs.present?
      data = []
      runs.each do |auth_name, run_count|
        auth_data = []
        auth_data[0] = auth_name
        failure_count = (failures.key? auth_name) ? failures[auth_name] : 0
        auth_data[1] = failure_count
        auth_data[2] = run_count - failure_count # passing
        data << auth_data
      end
      data
    end

    private
      def self.authorities_in_run(run_id:)
        QaServer::ScenarioRunHistory.where(scenario_run_registry_id: run_id).pluck(:authority_name).uniq
      end

      def self.authorities_with_failures_in_run(run_id:)
        QaServer::ScenarioRunHistory.where(scenario_run_registry_id: run_id).where.not(status: 'good').pluck('authority_name').uniq
      end

      def self.status_counts_in_run(run_id:)
        status = QaServer::ScenarioRunHistory.group('status').where(scenario_run_registry_id: run_id).count
        status["good"] = 0 unless status.key? "good"
        status["bad"] = 0 unless status.key? "bad"
        status["unknown"] = 0 unless status.key? "unknown"
        status
      end

      def self.all_runs_per_authority
        authority_runs = QaServer::ScenarioRunHistory.pluck(:authority_name, :scenario_run_registry_id).uniq
        runs_per_authority(authority_runs)
      end

      def self.failing_runs_per_authority
        failing_authority_runs = QaServer::ScenarioRunHistory.where.not(status: 'good').pluck(:authority_name, :scenario_run_registry_id).uniq
        runs_per_authority(failing_authority_runs)
      end

      def self.runs_per_authority(authority_runs)
        runs_per_authority = {}
        authority_runs.each do |auth_run|
          auth_name = auth_run[0]
          runs_per_authority[auth_name] = 0 unless runs_per_authority.key? auth_name
          runs_per_authority[auth_name] += 1
        end
        runs_per_authority
      end
  end
end
