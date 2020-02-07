# frozen_string_literal: true
# Provide access to the scenario_run_history database table which tracks scenario runs over time.
module QaServer
  class ScenarioRunHistory < ActiveRecord::Base
    self.table_name = 'scenario_run_history'
    belongs_to :scenario_run_registry
    enum scenario_type: [:connection, :accuracy, :performance], _suffix: :type
    enum status: [:good, :bad, :unknown], _suffix: true

    GOOD_MARKER = '√'
    BAD_MARKER = 'X'
    UNKNOWN_MARKER = '?'

    class_attribute :summary_class

    self.summary_class = QaServer::ScenarioRunSummary

    class << self
      # Save a scenario result
      # @param run_id [Integer] the run on which to gather statistics
      # @param result [Hash] the scenario result to be saved
      def save_result(run_id:, scenario_result:)
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
      # @param scenario_run [QaServer::ScenarioRunRegistry] the run on which to gather statistics
      # @param force [Boolean] if true, forces cache to regenerate; otherwise, returns value from cache unless expired
      # @returns [QaServer::ScenarioRunSummary] statistics on the requested run
      # @example ScenarioRunSummary includes methods for accessing
      #   * run_id: 14,
      #   * run_dt_stamp:
      #   * authority_count: 22,
      #   * failing_authority_count: 1
      #   * passing_scenario_count: 156,
      #   * failing_scenario_count: 3,
      #   * total_scenario_count: 159,
      def run_summary(scenario_run:, force: false)
        Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer.cache_expiry, race_condition_ttl: 1.hour, force: force) do
          Rails.logger.info("#{self.class}##{__method__} - creating summary of latest run - cache expired or refresh requested (#{force})")
          status = status_counts_in_run(run_id: scenario_run.id)
          summary_class.new(run_id: scenario_run.id,
                            run_dt_stamp: scenario_run.dt_stamp,
                            authority_count: authorities_in_run(run_id: scenario_run.id).count,
                            failing_authority_count: authorities_with_failures_in_run(run_id: scenario_run.id).count,
                            passing_scenario_count: status['good'],
                            failing_scenario_count: status['bad'] + status['unknown'])
        end
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
      # @deprecated Not used anywhere. Being removed.
      def run_results(run_id:, authority_name: nil, status: nil, url: nil)
        return [] unless run_id
        where = {}
        where[:scenario_run_registry_id] = run_id
        where[:authority_name] = authority_name if authority_name.present?
        where[:status] = status if status.present?
        where[:url] = url if url.present?
        QaServer::ScenarioRunHistory.where(where).to_a
      end
      deprecation_deprecate run_results: "Not used anywhere. Being removed."

      # Get set of failures for a run, if any.
      # @param run_id [Integer] the run on which to gather statistics
      # @param force [Boolean] if true, forces cache to regenerate; otherwise, returns value from cache unless expired
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
      def run_failures(run_id:, force: false)
        return [] unless run_id
        Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer.cache_expiry, race_condition_ttl: 1.hour, force: force) do
          Rails.logger.info("#{self.class}##{__method__} - finding failures in latest run - cache expired or refresh requested (#{force})")
          QaServer::ScenarioRunHistory.where(scenario_run_registry_id: run_id).where.not(status: :good).to_a
        end
      end

      # Get a summary level of historical data
      # @returns [Array<Array>] summary of passing/failing tests for each authority
      # @example [auth_name, failing, passing]
      #   { 'agrovoc' => { "good" => 0, "bad" => 24 },
      #     'geonames_ld4l_cache' => { "good" => 2, "bad" => 22 } }
      def historical_summary(force: false)
        Rails.cache.fetch("#{self.class}/#{__method__}", expires_in: QaServer.cache_expiry, race_condition_ttl: 1.hour, force: force) do
          runs_per_authority_for_time_period
        end
      end

      private

        def authorities_in_run(run_id:)
          QaServer::ScenarioRunHistory.where(scenario_run_registry_id: run_id).pluck(:authority_name).uniq
        end

        def authorities_with_failures_in_run(run_id:)
          QaServer::ScenarioRunHistory.where(scenario_run_registry_id: run_id).where.not(status: 'good').pluck('authority_name').uniq
        end

        # @return [Hash] status counts across all authorities (used for current test summary)
        # @example { "good" => 23, "bad" => 3, "unknown" => 0 }
        def status_counts_in_run(run_id:)
          status = QaServer::ScenarioRunHistory.group('status').where(scenario_run_registry_id: run_id).count
          status["good"] = 0 unless status.key? "good"
          status["bad"] = 0 unless status.key? "bad"
          status["unknown"] = 0 unless status.key? "unknown"
          status
        end

        def runs_per_authority_for_time_period
          status = QaServer::ScenarioRunHistory.joins(:scenario_run_registry).where(time_period_where).group('authority_name', 'status').count
          status.each_with_object({}) do |(k, v), hash|
            h = hash[k[0]] || { "good" => 0, "bad" => 0 } # initialize for an authority if it doesn't already exist
            h[k[1]] = v
            hash[k[0]] = h
          end
        end

        def expected_time_period
          QaServer.config.historical_datatable_default_time_period
        end

        def time_period_where
          case expected_time_period
          when :day
            QaServer::TimePeriodService.where_clause_for_last_24_hours(dt_table: :scenario_run_registry)
          when :month
            QaServer::TimePeriodService.where_clause_for_last_30_days(dt_table: :scenario_run_registry)
          when :year
            QaServer::TimePeriodService.where_clause_for_last_12_months(dt_table: :scenario_run_registry)
          else
            all_records
          end
        end
    end
  end
end
