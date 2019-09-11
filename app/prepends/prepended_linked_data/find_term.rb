# frozen_string_literal: true
module PrependedLinkedData::FindTerm
  # Override Qa::Authorities::LinkedData::FindTerm#find method
  # @return [Hash] single term results in requested format
  def find(id, language: nil, replacements: {}, subauth: nil, format: nil, jsonld: false, performance_data: false) # rubocop:disable Metrics/ParameterLists
    saved_performance_data = performance_data
    performance_data = true
    full_results = super
    return full_results unless full_results.is_a?(Hash) && full_results.key?(:performance)
    QaServer::PerformanceHistory.save_result(dt_stamp: Time.now.getlocal,
                                             authority: authority_name,
                                             action: 'fetch',
                                             size_bytes: full_results[:performance][:fetched_bytes],
                                             load_time_ms: (full_results[:performance][:fetch_time_s] * 1000),
                                             normalization_time_ms: (full_results[:performance][:normalization_time_s] * 1000))
    saved_performance_data ? full_results : full_results[:results]
  end
end
