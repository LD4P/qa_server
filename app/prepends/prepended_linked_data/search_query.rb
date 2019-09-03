# frozen_string_literal: true
module PrependedLinkedData::SearchQuery
  # Override Qa::Authorities::LinkedData::SearchQuery#search method
  # @return [String] json results for search query
  def search(query, language: nil, replacements: {}, subauth: nil, context: false, performance_data: false) # rubocop:disable Metrics/ParameterLists
    saved_performance_data = performance_data
    performance_data = true
    full_results = super
    QaServer::PerformanceHistory.save_result(dt_stamp: Time.now,
                                             authority: authority_name,
                                             action: 'search',
                                             size_bytes: full_results[:performance][:fetched_bytes],
                                             load_time_ms: (full_results[:performance][:fetch_time_s] * 1000),
                                             normalization_time_ms: (full_results[:performance][:normalization_time_s] * 1000))
    saved_performance_data ? full_results : full_results[:results]
  end
end
