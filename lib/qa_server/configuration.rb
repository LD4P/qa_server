# frozen_string_literal: true
module QaServer
  class Configuration
    # Preferred time zone for reporting historical data and performance data
    # @param [String] time zone name
    # @see https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html for possible values of TimeZone names
    attr_writer :preferred_time_zone_name
    def preferred_time_zone_name
      @preferred_time_zone_name ||= 'Eastern Time (US & Canada)'
    end

    # Set preferred hour to expire caches related to slow running calculations (e.g. monitoring tests, performance data)
    # @param [Integer] count of hours after midnight (0-23 with 0=midnight)
    # @raise [ArgumentError] if offset is not between 0 and 23
    # @example
    #   For preferred_time_zone_name of 'Eastern Time (US & Canada)', use 3 for slow down at midnight PT/3am ET
    #   For preferred_time_zone_name of 'Pacific Time (US & Canada)', use 0 for slow down at midnight PT/3am ET
    def hour_offset_to_expire_cache=(offset)
      raise ArgumentError, 'offset must be between 0 and 23' unless (0..23).cover? offset
      @hour_offset_to_expire_cache = offset
    end

    # Preferred hour to expire caches related to slow running calculations (e.g. monitoring tests, performance data)
    # @return [Integer] count of hours after midnight (0-23 with 0=midnight)
    def hour_offset_to_expire_cache
      @hour_offset_to_expire_cache ||= 3
    end

    # Set preferred hour to run monitoring tests (deprecated)
    # @param [Integer] count of hours from midnight (0-23 with 0=midnight)
    # @example
    #   For preferred_time_zone_name of 'Eastern Time (US & Canada)', use 3 for slow down at midnight PT/3am ET
    #   For preferred_time_zone_name of 'Pacific Time (US & Canada)', use 0 for slow down at midnight PT/3am ET
    # @deprecated Use {#hour_offset_to_expire_cache=} instead.
    def hour_offset_to_run_monitoring_tests=(offset)
      Deprecation.warn(QaServer, "hour_offset_to_run_monitoring_tests= is deprecated and will be removed from a future release (use #hour_offset_to_expire_cache= instead)")
      @hour_offset_to_expire_cache = offset
    end

    # Preferred hour to run monitoring tests (deprecated)
    # @return [Integer] count of hours from midnight (0-23 with 0=midnight)
    # @deprecated Use {#hour_offset_to_expire_cache} instead.
    alias hour_offset_to_run_monitoring_tests hour_offset_to_expire_cache
    deprecation_deprecate hour_offset_to_run_monitoring_tests: "use #hour_offset_to_expire_cache instead"

    # Displays a graph of historical test data when true
    # @param [Boolean] display history graph when true
    attr_writer :display_historical_graph
    def display_historical_graph?
      return @display_historical_graph unless @display_historical_graph.nil?
      @display_historical_graph = false
    end

    # Displays a datatable of historical test data when true
    # @param [Boolean] display history datatable when true
    attr_writer :display_historical_datatable
    def display_historical_datatable?
      return @display_historical_datatable unless @display_historical_datatable.nil?
      @display_historical_datatable = true
    end

    # Historical datatable default time period.
    # @param [Symbol] time period for calculating historical pass/fail (i.e., one of :month, :year, or :all)
    # @raise [ArgumentError] if time_period is not one of :month, :year, or :all
    def historical_datatable_default_time_period=(time_period)
      raise ArgumentError, 'time_period must be one of :day, :month, or :year' unless [:month, :year, :all].include? time_period
      @historical_datatable_default_time_period = time_period
    end

    # Historical datatable default time period.
    # @return [Symbol] time period for calculating historical pass/fail (i.e., one of :month, :year, or :all)
    def historical_datatable_default_time_period
      @historical_datatable_default_time_period ||= :year
    end

    # Displays a graph of performance test data when true
    # @param [Boolean] display performance graph when true
    attr_writer :display_performance_graph
    def display_performance_graph?
      return @display_performance_graph unless @display_performance_graph.nil?
      @display_performance_graph = false
    end

    # Max time in milliseconds for y-axis in the performance graphs.
    attr_writer :performance_y_axis_max
    def performance_y_axis_max
      @performance_y_axis_max ||= 4000
    end

    # Color of the graph line for retrieve times in the performance graphs.
    # @param [String] color RGB code
    # @note The default colors for the retrieve, graph_load, load, normalization, and full request lines in the performance graph are accessible.
    attr_writer :performance_retrieve_color
    def performance_retrieve_color
      @performance_retrieve_color ||= '#ABC3C9'
    end

    # Color of the graph line for graph load times in the performance graphs.
    # @param [String] color RGB code
    # @note The default colors for the retrieve, graph_load, load, normalization, and full request lines in the performance graph are accessible.
    attr_writer :performance_graph_load_color
    def performance_graph_load_color
      @performance_graph_load_color ||= '#E8DCD3'
    end

    # Color of the graph line for normalization times in the performance graphs
    # @param [String] color RGB code
    # @note The default colors for the retrieve, graph_load, load, normalization, and full request lines in the performance graph are accessible.
    attr_writer :performance_normalization_color
    def performance_normalization_color
      @performance_normalization_color ||= '#CCBE9F'
    end

    # Performance graph default time period for all graphs.  All authorities will show the graph for this time period on page load.
    # @param [Symbol] time period for default display of performance graphs (i.e., one of :day, :month, or :year)
    # @raise [ArgumentError] if time_period is not one of :day, :month, or :year
    def performance_graph_default_time_period=(time_period)
      raise ArgumentError, 'time_period must be one of :day, :month, or :year' unless [:day, :month, :year].include? time_period
      @performance_graph_default_time_period = time_period
    end

    # Performance graph default time period for all graphs.  All authorities will show the graph for this time period on page load.
    # @return [Symbol] time period for default display of performance graphs (i.e., one of :day, :month, or :year)
    def performance_graph_default_time_period
      @performance_graph_default_time_period ||= :month
    end

    # Displays a datatable of performance test data when true
    # @param [Boolean] display performance datatable when true
    attr_writer :display_performance_datatable
    def display_performance_datatable?
      return @display_performance_datatable unless @display_performance_datatable.nil?
      @display_performance_datatable = true
    end

    # Performance datatable default time period for calculating stats.
    # @param [Symbol] time period for calculating performance stats (i.e., one of :day, :month, :year, or :all)
    # @raise [ArgumentError] if time_period is not one of :day, :month, :year, or :all
    def performance_datatable_default_time_period=(time_period)
      raise ArgumentError, 'time_period must be one of :day, :month, :year, or :all' unless [:day, :month, :year, :all].include? time_period
      @performance_datatable_default_time_period = time_period
    end

    # Performance datatable default time period for calculating stats.
    # @return [Symbol] time period for calculating performance stats (i.e., one of :day, :month, :year, or :all)
    def performance_datatable_default_time_period
      @performance_datatable_default_time_period ||= :year
    end

    # Performance datatable targeted maximum full request time.
    # @param [Integer] targeted maximum full request time in ms
    attr_writer :performance_datatable_max_threshold
    def performance_datatable_max_threshold
      @performance_datatable_max_threshold ||= 1500
    end

    # Performance datatable targeted warning full request time.
    # @param [Integer] targeted warning full request time in ms
    attr_writer :performance_datatable_warning_threshold
    def performance_datatable_warning_threshold
      @performance_datatable_warning_threshold ||= 1000
    end

    # Additional menu items to add to the main navigation menu's set of left justified menu items
    # @param [Array<Hash<String,String>>] array of menu items to append with hash key = menu item label to display and hash value = URL for the menu item link
    # @example
    #   [
    #     { label: 'New Item Label', url: 'http://new.item/one' },
    #     { label: '2nd New Item Label', url: 'http://new.item/two' }
    #   ]
    attr_accessor :navmenu_extra_leftitems

    # Get the one and only instance of the navigation menu presenter used to construct the main navigation menu.
    # To extend, set additional navigation menu items using #navmenu_extra_leftitems
    def navmenu_presenter
      return @navmenu_presenter if @navmenu_presenter.present?
      @navmenu_presenter ||= QaServer::NavmenuPresenter.new
      @navmenu_presenter.append_leftmenu_items(navmenu_extra_leftitems)
      @navmenu_presenter
    end

    def performance_tracker
      @performance_tracker ||= File.new('log/performance.csv', 'w').tap do |f|
        f.puts('action, http request, load graph, normalization, TOTAL, data size, authority')
      end
    end

    # Performance data is gathered on every incoming query.  If load is high, this can have a negative performance
    # impact and may need to be suppressed.  Performance stats will not be gathered when this config is true.
    # @param [Boolean] do not gather performance data when true (defaults to false for backward compatibitily)
    attr_writer :suppress_performance_gathering
    def suppress_performance_gathering
      @suppress_performance_gathering ||= false
    end

    # Performance data is gathered on every incoming query.  Basic stats are logged from QA.  Full stats are logged
    # by QaServer and can eat up logging realestate.  To suppress the logging of details, set this config to true.
    # @param [Boolean] do not log performance data details when true (defaults to false for backward compatibitily)
    attr_writer :suppress_logging_performance_datails
    def suppress_logging_performance_datails
      @suppress_logging_performance_datails ||= false
    end

    # For internal use only
    # TODO: consider refactor performance caching to use Rails cache
    def performance_cache
      @performance_cache ||= QaServer::PerformanceCache.new
    end

    # For internal use only
    def jobs_logger
      @jobs_logger ||= Logger.new(ENV['JOBS_LOG_PATH'] || File.join("log", "jobs.log"))
    end
  end
end
