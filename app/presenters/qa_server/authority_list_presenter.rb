# This presenter class provides all data needed by the view that show the list of authorities.
module QaServer
  class AuthorityListPresenter
    def initialize(urls_data:)
      @urls_data = urls_data
    end

    # @return [Array<Hash>] A list of status data for each scenario tested.
    # @example
    #   { status: :PASS,
    #     status_label: '√',
    #     authority_name: 'LOCNAMES_LD4L_CACHE',
    #     subauthority_name: 'person',
    #     service: 'ld4l_cache',
    #     action: 'search',
    #     url: '/qa/search/linked_data/locnames_ld4l_cache/person?q=mark twain&maxRecords=4',
    #     err_message: '' }
    def urls_data
      @urls_data
    end
  end
end
