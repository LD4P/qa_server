# frozen_string_literal: true
# Controller for Check Status header menu item
module QaServer
  class FetchController < ApplicationController
    layout 'qa_server'

    class_attribute :presenter_class,
                    :lister_class

    self.presenter_class = QaServer::FetchPresenter
    self.lister_class = QaServer::AuthorityListerService

    # Sets up presenter with data to display in the UI
    def index
      flash[:error] = "Authority is required." if uri? && !authority_name?
      @presenter = presenter_class.new(authorities_list: authorities_list,
                                       authority: authority_name,
                                       uri: uri,
                                       format: format,
                                       term_results: term_results)
    end

  private

    def authorities_list
      @authorities_list ||= lister_class.authorities_list
    end

    # @return [Qa::Authorities::LinkedData::GenericAuthority] the instance of the QA authority
    def authority
      return unless authority_name?
      @authority ||= QaServer::AuthorityLoaderService.load(authority_name: authority_name)
    end

    def uri?
      uri.present?
    end

    def uri
      @uri ||= params.key?(:uri) ? params[:uri] : nil
    end

    def authority_name?
      authority_name.present?
    end

    def authority_name
      @authority_name ||= params.key?(:authority) ? params[:authority].downcase : nil
    end

    def format
      @format ||= params.key?(:results_format) ? params[:results_format] : 'json'
    end

    def term_results
      return unless authority_name? && uri?
      @term_results = authority.find(uri, format: format)
    end
  end
end
