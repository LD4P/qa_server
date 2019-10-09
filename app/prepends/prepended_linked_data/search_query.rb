# frozen_string_literal: true
module PrependedLinkedData::SearchQuery
  # Override Qa::Authorities::LinkedData::SearchQuery#search method
  # @return [String] json results for search query
  def search(query, language: nil, replacements: {}, subauth: nil, context: false, performance_data: false) # rubocop:disable Metrics/ParameterLists
    start_time_s = Time.now.to_f

    saved_performance_data = performance_data
    performance_data = true
    ph_record = QaServer::PerformanceHistory.create_record(authority: authority_name, action: 'search')
    @phid = ph_record.id
    begin
      full_results = super
      update_performance_history_record(full_results, start_time_s)
    rescue Exception => e # rubocop:disable Lint/RescueException
      ph_record.destroy
      raise e
    end
    saved_performance_data || !full_results.key?(:results) ? full_results : full_results[:results]
  end

  private

    def update_performance_history_record(full_results, start_time_s)
      ph_record = QaServer::PerformanceHistory.find(@phid)
      return ph_record.destroy unless full_results.is_a?(Hash) && full_results.key?(:performance)
      ph_record.action_time_ms = (Time.now.to_f - start_time_s) * 1000
      ph_record.size_bytes = full_results[:performance][:fetched_bytes]
      ph_record.retrieve_plus_graph_load_time_ms = full_results[:performance][:fetch_time_s] * 1000
      ph_record.normalization_time_ms = full_results[:performance][:normalization_time_s] * 1000
      ph_record.save
    end

    # Override to append performance history record id into the URL to allow access to the record in RDF::Graph
    def load_graph(url:)
      access_start_dt = Time.now.utc

      url += "&phid=#{@phid}"
      @full_graph = graph_service.load_graph(url: url)

      access_end_dt = Time.now.utc
      @access_time_s = access_end_dt - access_start_dt
      @fetched_size = full_graph.triples.to_s.size if performance_data?
      Rails.logger.info("Time to receive data from authority: #{access_time_s}s")
    end
end
