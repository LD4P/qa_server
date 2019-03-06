# frozen_string_literal: true

require 'fileutils'
require 'gruff'

# This presenter class provides all data needed by the view that monitors status of authorities.
module QaServer
  class MonitorStatusPresenter # rubocop:disable Metrics/ClassLength
    HISTORICAL_AUTHORITY_NAME_IDX = 0
    HISTORICAL_FAILURE_COUNT_IDX = 1
    HISTORICAL_PASSING_COUNT_IDX = 2

    # @param current_summary [ScenarioRunSummary] summary status of the latest run of test scenarios
    # @param current_data [Array<Hash>] current set of failures for the latest test run, if any
    # @param historical_summary_data [Array<Hash>] summary of past failuring runs per authority to drive chart
    def initialize(current_summary:, current_failure_data:, historical_summary_data:, performance_data:)
      @current_summary = current_summary
      @current_failure_data = current_failure_data
      @historical_summary_data = historical_summary_data
      @performance_data = performance_data
    end

    # @return [String] date of last test run
    def last_updated
      @current_summary.run_dt_stamp.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%y - %I:%M %p")
    end

    # @return [String] date of first recorded test run
    def first_updated
      QaServer::ScenarioRunRegistry.first.dt_stamp.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%y - %I:%M %p")
    end

    # @return [Integer] number of loaded authorities
    def authorities_count
      @current_summary.authority_count
    end

    # @return [Integer] number of authorities with failing tests in the latest test run
    def failing_authorities_count
      @current_failure_data.map { |f| f[:authority_name] }.uniq.count
    end

    # @return [String] css style class representing whether all tests passed or any failed
    def authorities_count_style
      failures? ? 'status-bad' : 'status-good'
    end

    # @return [Integer] number of tests in the latest test run
    def tests_count
      @current_summary.total_scenario_count
    end

    # @return [Integer] number of passing tests in the latest test run
    def passing_tests_count
      @current_summary.passing_scenario_count
    end

    # @return [Integer] number of failing tests in the latest test run
    def failing_tests_count
      @current_summary.failing_scenario_count
    end

    # @return [String] css style class representing whether all tests passed or any failed
    def failing_tests_style
      failures? ? 'summary-status-bad' : 'status-good'
    end

    # @return [Array<Hash>] A list of failures data in the latest test run, if any
    # @example
    #   [ { status: :FAIL,
    #       status_label: 'X',
    #       authority_name: 'LOCNAMES_LD4L_CACHE',
    #       subauthority_name: 'person',
    #       service: 'ld4l_cache',
    #       action: 'search',
    #       url: '/qa/search/linked_data/locnames_ld4l_cache/person?q=mark twain&maxRecords=4',
    #       err_message: 'Exception: Something went wrong.' }, ... ]
    def failures
      @current_failure_data
    end

    # @return [Boolean] true if failure data exists for the latest test run; otherwise false
    def failures?
      failing_tests_count.positive?
    end

    # @return [Array<Hash>] historical test data to be displayed (authname, failing, passing)
    # @example
    #   [ [ 'agrovoc', 0, 24 ],
    #     [ 'geonames_ld4l_cache', 2, 22 ] ... ]
    def historical_summary
      @historical_summary_data
    end

    # @return [Boolean] true if historical test data exists; otherwise false
    def history?
      return true if @historical_summary_data.present?
      false
    end

    def historical_graph
      # g = Gruff::SideStackedBar.new('800x400')
      g = Gruff::SideStackedBar.new
      graph_theme(g)
      g.title = ''
      historical_data = rework_historical_data_for_gruff
      g.labels = historical_data[0]
      g.data('Fail', historical_data[1])
      g.data('Pass', historical_data[2])
      g.write historical_graph_full_path
      File.join(historical_graph_relative_path, historical_graph_filename)
    end

    # @return [String] the name of the css style class to use for the status cell based on the status of the scenario test.
    def status_style_class(status)
      "status-#{status[:status]}"
    end

    # @return [String] the name of the css style class to use for the status cell based on the status of the scenario test.
    def status_label(status)
      case status[:status]
      when :good
        QaServer::ScenarioRunHistory::GOOD_MARKER
      when :bad
        QaServer::ScenarioRunHistory::BAD_MARKER
      when :unknown
        QaServer::ScenarioRunHistory::UNKNOWN_MARKER
      end
    end

    def historical_data_authority_name(historical_entry)
      historical_entry[QaServer::MonitorStatusPresenter::HISTORICAL_AUTHORITY_NAME_IDX]
    end

    def days_authority_passing(historical_entry)
      historical_entry[QaServer::MonitorStatusPresenter::HISTORICAL_PASSING_COUNT_IDX]
    end

    def days_authority_failing(historical_entry)
      historical_entry[QaServer::MonitorStatusPresenter::HISTORICAL_FAILURE_COUNT_IDX]
    end

    def days_authority_tested(historical_entry)
      days_authority_passing(historical_entry) + days_authority_failing(historical_entry)
    end

    def percent_authority_failing(historical_entry)
      days_authority_failing(historical_entry).to_f / days_authority_tested(historical_entry)
    end

    def percent_authority_failing_str(historical_entry)
      "#{percent_authority_failing(historical_entry) * 100}%"
    end

    def failure_style_class(historical_entry)
      return "status-neutral" if days_authority_failing(historical_entry) <= 0
      return "status-unknown" if percent_authority_failing(historical_entry) < 0.1
      "status-bad"
    end

    def passing_style_class(historical_entry)
      return "status-bad" if days_authority_passing(historical_entry) <= 0
      "status-good"
    end

    def display_history_details?
      display_historical_graph? || display_historical_datatable?
    end

    def display_historical_graph?
      QaServer.config.display_historical_graph?
    end

    def display_historical_datatable?
      QaServer.config.display_historical_datatable?
    end

    private

      def graph_theme(g)
        g.theme_pastel
        g.colors = ['#ffcccc', '#ccffcc']
        g.marker_font_size = 12
        g.x_axis_increment = 10
      end

      def historical_graph_full_path
        path = Rails.root.join('app', 'assets', 'images', historical_graph_relative_path)
        FileUtils.mkdir_p path
        File.join(path, historical_graph_filename)
      end

      def historical_graph_relative_path
        File.join('qa_server', 'charts')
      end

      def historical_graph_filename
        'historical_side_stacked_bar.png'
      end

      def rework_historical_data_for_gruff
        labels = {}
        pass_data = []
        fail_data = []
        i = 0
        historical_summary.each do |data|
          labels[i] = data[0]
          i += 1
          fail_data << data[1]
          pass_data << data[2]
        end
        [labels, fail_data, pass_data]
      end
  end
end
