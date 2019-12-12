# frozen_string_literal: true
QaServer.config do |config|
  # Preferred time zone for reporting historical data and performance data
  # @param [String] time zone name
  # @see https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html for possible values of TimeZone names
  # config.preferred_time_zone_name = 'Eastern Time (US & Canada)'

  # Preferred hour to run monitoring tests
  # @param [Integer] count of hours from midnight (0-23 with 0=midnight)
  # @example
  #   For preferred_time_zone_name of 'Eastern Time (US & Canada)', use 3 for slow down at midnight PT/3am ET
  #   For preferred_time_zone_name of 'Pacific Time (US & Canada)', use 0 for slow down at midnight PT/3am ET
  # config.hour_offset_to_run_monitoring_tests = 3

  # Displays a graph of historical test data when true
  # @param [Boolean] display history graph when true
  # config.display_historical_graph = false

  # Displays a datatable of historical test data when true
  # @param [Boolean] display history datatable when true
  # config.display_historical_datatable = true

  # Displays a graph of performance test data when true
  # @param [Boolean] display performance graph when true
  # config.display_performance_graph = false

  # Max time in milliseconds for y-axis in the performance graphs.
  # @param [Integer] milliseconds
  # config.performance_y_axis_max = 4000

  # Color of the graph line for retrieve times in the performance graphs.
  # @param [String] color RGB code
  # @note The default colors for the retrieve, graph_load, load, normalization, and full request lines in the performance graph are accessible.
  # config.performance_retrieve_color = '#ABC3C9'

  # Color of the graph line for graph load times in the performance graphs.
  # @param [String] color RGB code
  # @note The default colors for the retrieve, graph_load, normalization, and full request lines in the performance graph are accessible.
  # config.performance_graph_load_color = '#E8DCD3'

  # Color of the graph line for normalization times in the performance graphs
  # @param [String] color RGB code
  # @note The default colors for the retrieve, graph_load, load, normalization, and full request lines in the performance graph are accessible.
  # config.performance_normalization_color = '#CCBE9F'

  # Performance graph default time period for all graphs.  All authorities will show the graph for this time period on page load.
  # @param [String] :day, :month, or :year
  # config.performance_graph_default_time_period = :month

  # Displays a datatable of performance test data when true
  # @param [Boolean] display performance datatable when true
  # config.display_performance_datatable = true

  # Performance datatable default time period for calculating stats.
  # @param [String] :day, :month, :year, :all
  # config.performance_datatable_default_time_period = :year

  # Performance datatable targeted maximum full request time.
  # @param [Integer] targeted maximum full request time in ms
  # config.performance_datatable_max_threshold = 1500

  # Performance datatable targeted warning full request time.
  # @param [Integer] targeted warning full request time in ms
  # config.performance_datatable_warning_threshold = 1000

  # Additional menu items to add to the main navigation menu's set of left justified menu items
  # @param [Array<Hash<String,String>>] array of menu items to append with hash label: is menu item label to display and hash url: is URL for the menu item link
  # config.navmenu_extra_leftitems = [
  #   { label: 'Your Menu Item Label', url: 'http://your.menu.item/url' }
  # ]

  # Performance data is gathered on every incoming query.  If load is high, this can have a negative performance
  # impact and may need to be suppressed.  Performance stats will not be gathered when this config is true.
  # @param [Boolean] do not gather performance data when true (defaults to false for backward compatibitily)
  # config.suppress_performance_gathering = false
end
