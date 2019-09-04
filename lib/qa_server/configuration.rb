# frozen_string_literal: true
module QaServer
  class Configuration
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

    # Displays a graph of performance test data when true
    # @param [Boolean] display performance graph when true
    attr_writer :display_performance_graph
    def display_performance_graph?
      return @display_performance_graph unless @display_performance_graph.nil?
      @display_performance_graph = false
    end

    # Displays a datatable of performance test data when true
    # @param [Boolean] display performance datatable when true
    attr_writer :display_performance_datatable
    def display_performance_datatable?
      return @display_performance_datatable unless @display_performance_datatable.nil?
      @display_performance_datatable = true
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
  end
end
