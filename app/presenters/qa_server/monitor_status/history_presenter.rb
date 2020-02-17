# frozen_string_literal: true
# This presenter class provides historical testing data needed by the view that monitors status of authorities.
module QaServer::MonitorStatus
  class HistoryPresenter # rubocop:disable Metrics/ClassLength
    include QaServer::MonitorStatus::GruffGraph

    # @param parent [QaServer::MonitorStatusPresenter] parent presenter
    # @param historical_summary_data [Array<Hash>] summary of past failuring runs per authority to drive chart
    def initialize(parent:, historical_summary_data:)
      @parent = parent
      @historical_summary_data = historical_summary_data
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
      @historical_summary_data.present?
    end

    # Return the first date of data represented in the history graph and data table
    # @return [String] string version of date formatted with just date (e.g. "02/01/2020")
    def history_start
      start_dt = case QaServer.config.historical_datatable_default_time_period
                 when :month
                   history_end_dt - 1.month
                 when :year
                   history_end_dt - 1.year
                 else
                   @parent.first_updated_dt
                 end
      QaServer::TimeService.pretty_date(start_dt)
    end

    # Return the last date of data represented in the history graph and data table
    # @return [ActiveSupport::TimeWithZone] date time stamp
    def history_end_dt
      @parent.last_updated_dt
    end

    # Return the last date of data represented in the history graph and data table
    # @return [String] string version of date formatted with just date (e.g. "02/01/2020")
    def history_end
      QaServer::TimeService.pretty_date(history_end_dt)
    end

    def historical_graph
      # g = Gruff::SideStackedBar.new('800x400')
      g = Gruff::SideStackedBar.new
      historical_graph_theme(g)
      historical_data = rework_historical_data_for_gruff
      g.labels = historical_data[0]
      g.data('Fail', historical_data[1])
      g.data('Pass', historical_data[2])
      g.write historical_graph_full_path
      File.join(graph_relative_path, historical_graph_filename)
    end

    # @return [String] the name of the css style class to use for the status cell based on the status of the scenario test.
    def status_style_class(status)
      "status-#{status[:status]}"
    end

    # @return [String] the marker to use for the status cell based on the status of the scenario test
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
      historical_entry[0]
    end

    def days_authority_passing(historical_entry)
      historical_entry[1][:good]
    end

    def days_authority_failing(historical_entry)
      historical_entry[1][:bad]
    end

    def days_authority_tested(historical_entry)
      days_authority_passing(historical_entry) + days_authority_failing(historical_entry)
    end

    def percent_authority_failing(historical_entry)
      days_authority_failing(historical_entry).to_f / days_authority_tested(historical_entry)
    end

    def percent_authority_failing_str(historical_entry)
      ActiveSupport::NumberHelper.number_to_percentage(percent_authority_failing(historical_entry) * 100, precision: 1)
    end

    def failure_style_class(historical_entry)
      return "status-neutral" if days_authority_failing(historical_entry) <= 0
      percent_authority_failing(historical_entry) < 0.10 ? "status-unknown" : "status-bad"
    end

    def passing_style_class(historical_entry)
      days_authority_passing(historical_entry) <= 0 ? "status-bad" : "status-good"
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

      def historical_graph_theme(g)
        g.theme_pastel
        g.colors = ['#ffcccc', '#ccffcc']
        g.marker_font_size = 12
        g.x_axis_increment = 10
      end

      def historical_graph_full_path
        graph_full_path(historical_graph_filename)
      end

      def historical_graph_filename
        'historical_side_stacked_bar.png'
      end

      def rework_historical_data_for_gruff
        labels = {}
        pass_data = []
        fail_data = []
        i = 0
        historical_summary.each do |auth, data|
          labels[i] = auth
          i += 1
          fail_data << data[:bad]
          pass_data << data[:good]
        end
        [labels, fail_data, pass_data]
      end
  end
end
