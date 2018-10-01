# frozen_string_literal: true
# This presenter class provides all data needed by the view that show the list of authorities.
module QaServer
  class NavmenuPresenter
    include QaServer::Engine.routes.url_helpers

    # @return [Array<Hash>] label-url pairs for the navigation bar's menu items justified left
    # @example
    #   [
    #     { label: 'Home', url: '/' },
    #     { label: 'Usage', url: '/usage' },
    #     { label: 'Authorities', url: '/authorities' },
    #     { label: 'Check Status', url: '/check_status' },
    #     { label: 'Monitor Status', url: '/monitor_status' }
    #   ]
    attr_reader :leftmenu_items

    # @return [Array<Hash>] label-url pairs for the navigation bar's menu items justified right
    # @example
    #   [
    #     { label: 'LD4L Gateway', url: 'http://ld4l.org' }
    #   ]
    attr_reader :rightmenu_items

    def initialize
      @leftmenu_items = []
      @leftmenu_items << { label: I18n.t("qa_server.menu.home"), url: root_path }
      @leftmenu_items << { label: I18n.t("qa_server.menu.usage"), url: usage_index_path }
      @leftmenu_items << { label: I18n.t("qa_server.menu.authorities"), url: authority_list_index_path }
      @leftmenu_items << { label: I18n.t("qa_server.menu.check_status"), url: check_status_index_path }
      @leftmenu_items << { label: I18n.t("qa_server.menu.monitor_status"), url: monitor_status_index_path }

      @rightmenu_items = []
      @rightmenu_items << { label: "LD4L Gateway", url: "http://ld4l.org/" }
    end

    # Append additional left justified menu items to the main navigation menu
    # @param [Array<Hash<String,String>>] array of menu items to append with hash key = menu item label to display and hash value = URL for the menu item link
    # @example
    #   [
    #     { label: 'New Item Label', url: 'http://new.item/one' },
    #     { label: '2nd New Item Label', url: 'http://new.item/two' }
    #   ]
    def append_leftmenu_items(additional_items = [])
      return if additional_items.nil?
      additional_items.each { |item| @leftmenu_items << item }
    end
  end
end
