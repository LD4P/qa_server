# frozen_string_literal: true
# Abstract class that parses the authority configuration from the yml file into the parts needed by inheriting scenario types.
module QaServer
  class ScenarioRunSummary
    # @return [Integer] the id of the scenario run being summarized
    attr_reader :run_id

    # @return [Date] the date time stamp of the scenario run being summarized
    attr_reader :run_dt_stamp

    # @return [Integer] number of all authorities in the run
    attr_reader :authority_count

    # @return [Integer] number of authorities in the run that had at least one failing test
    attr_reader :failing_authority_count

    # @return [Integer] number of scenarios that passed during this run
    attr_reader :passing_scenario_count

    # @return [Integer] name of the subauthority the scenario runs against
    attr_reader :failing_scenario_count

    # @return [Integer] total number of scenarios in this run
    attr_reader :total_scenario_count

    # @param run_id [Integer] the id of the scenario run being summarized
    # @param run_dt_stamp [Date] the date time stamp of the scenario run being summarized
    # @param authority_count [Integer] number of all authorities in the run
    # @param failing_authority_count [Integer] number of authorities in the run that had failing tests
    # @param passing_scenario_count [Integer] number of scenarios that passed during this run
    # @param failing_scenario_count [Integer] number of scenarios that failed during this run
    # rubocop:disable Metrics/ParameterLists
    def initialize(run_id:, run_dt_stamp:, authority_count:, failing_authority_count:, passing_scenario_count:, failing_scenario_count:)
      @run_id = run_id
      @run_dt_stamp = run_dt_stamp
      @authority_count = authority_count
      @failing_authority_count = failing_authority_count
      @passing_scenario_count = passing_scenario_count
      @failing_scenario_count = failing_scenario_count
      @total_scenario_count = failing_scenario_count + passing_scenario_count
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
