# frozen_string_literal: true
QaServer.config do |config|
  # Displays a graph of historical test data when true
  # @param [Boolean] display history graph when true
  # config.display_historical_graph = false

  # Displays a datatable of historical test data when true
  # @param [Boolean] display history datatable when true
  # config.display_historical_datatable = true

  # Displays a graph of performance test data when true
  # @param [Boolean] display performance graph when true
  # config.display_performance_graph = false

  # Color of the graph line for load times in the performance graphs.
  # @param [String] color RGB code
  # @note The default colors for the load, normalization, and full request lines in the performance graph are accessible.
  # config.performance_load_color = '#CCBE9F'

  # Color of the graph line for normalization times (The default colors for the performance graph are accessible.)
  # @param [String] color RGB code
  # @note The default colors for the load, normalization, and full request lines in the performance graph are accessible.
  # config.performance_normalization_color = '#ABC3C9'

  # Color of the graph line for full request times (The default colors for the performance graph are accessible.)
  # @param [String] color RGB code
  # @note The default colors for the load, normalization, and full request lines in the performance graph are accessible.
  # config.performance_full_request_color = '#382119'

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
end
