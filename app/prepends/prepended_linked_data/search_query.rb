# frozen_string_literal: true
module PrependedLinkedData::SearchQuery
  # Override Qa::Authorities::LinkedData::SearchQuery#search method
  # @return [String] json results for search query
  def search(query, request_header: {}, language: nil, replacements: {}, subauth: nil, context: false, performance_data: false) # rubocop:disable Metrics/ParameterLists
    return super if QaServer.config.suppress_performance_gathering
    request_header = setup_search(request_header: request_header, language: language, replacements: replacements, subauth: subauth,
                                  context: context, performance_data: performance_data)
    @phid = QaServer.config.performance_cache.new_entry(authority: authority_name, action: 'search')
    begin
      full_results = super
      update_performance_history_record(full_results)
    rescue Exception => e # rubocop:disable Lint/RescueException
      QaServer.config.performance_cache.destroy(@phid)
      raise e
    end
    requested_results(full_results)
  end

  private

    def setup_search(request_header: {}, language: nil, replacements: {}, subauth: nil, context: false, performance_data: false) # rubocop:disable Metrics/ParameterLists
      QaServer.log_agent_info(request_header[:request])
      @start_time_s = QaServer::TimeService.current_time_s
      request_header = build_request_header(language: language, replacements: replacements, subauth: subauth, context: context, performance_data: performance_data) if request_header.empty?
      @saved_performance_data = performance_data || request_header[:performance_data]
      request_header[:performance_data] = true
      request_header
    end

    def update_performance_history_record(full_results)
      return QaServer.config.performance_cache.destroy(@phid) unless full_results.is_a?(Hash) && full_results.key?(:performance)
      updates = { action_time_ms: (QaServer::TimeService.current_time_s - @start_time_s) * 1000,
                  size_bytes: full_results[:performance][:fetched_bytes],
                  retrieve_plus_graph_load_time_ms: full_results[:performance][:fetch_time_s] * 1000,
                  normalization_time_ms: full_results[:performance][:normalization_time_s] * 1000 }
      QaServer.config.performance_cache.update(id: @phid, updates: updates)
      QaServer.config.performance_cache.complete_entry(id: @phid)
    end

    # Override to append performance history record id into the URL to allow access to the record in RDF::Graph
    def load_graph(url:)
      return super if QaServer.config.suppress_performance_gathering

      access_start_dt = QaServer::TimeService.current_time

      url += "&phid=#{@phid}"
      @full_graph = graph_service.load_graph(url: url)

      access_end_dt = QaServer::TimeService.current_time
      @access_time_s = access_end_dt - access_start_dt
      @fetched_size = full_graph.triples.to_s.size if performance_data?
      Rails.logger.info("Time to receive data from authority: #{access_time_s}s")
    end

    def requested_results(full_results)
      return full_results if @saved_performance_data
      return full_results[:results] unless full_results.key? :response_header
      full_results.delete(:performance)
      full_results
    end
end
