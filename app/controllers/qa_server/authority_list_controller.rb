# frozen_string_literal: true
# Controller for Authorities header menu item
module QaServer
  class AuthorityListController < ApplicationController
    layout 'qa_server'

    include QaServer::AuthorityValidationBehavior

    class_attribute :presenter_class
    self.presenter_class = QaServer::AuthorityListPresenter

    # Sets up presenter with data to display in the UI
    def index
      list(authorities_list)
      @presenter = presenter_class.new(urls_data: status_data_from_log)
    end
  end
end
