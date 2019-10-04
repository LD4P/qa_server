# frozen_string_literal: true
module PrependedLinkedData::SearchQuery
  # Override Qa::Authorities::LinkedData::SearchQuery#search method
  # @return [String] json results for search query
  def search(query, language: nil, replacements: {}, subauth: nil, context: false, performance_data: false) # rubocop:disable Metrics/ParameterLists
    start_time_s = start_timing

    saved_performance_data = performance_data
    performance_data = true
    full_results = super
    return full_results unless full_results.is_a?(Hash) && full_results.key?(:performance)
    QaServer::PerformanceHistory.save_result(dt_stamp: Time.now.getlocal,
                                             authority: authority_name,
                                             action: 'search',
                                             size_bytes: full_results[:performance][:fetched_bytes],
                                             load_time_ms: (full_results[:performance][:fetch_time_s] * 1000),
                                             normalization_time_ms: (full_results[:performance][:normalization_time_s] * 1000))

    end_timing(start_time_s, full_results)
    saved_performance_data ? full_results : full_results[:results]
  end

  private

    def start_timing
      QaServer.config.performance_tracker.write 'search, ' # action
      Time.now.to_f
    end

    def end_timing(start_time_s, full_results)
      end_time_s = Time.now.to_f
      QaServer.config.performance_tracker.write "#{'%.6f' % (full_results[:performance][:normalization_time_s])}, " # normalization
      QaServer.config.performance_tracker.write "#{'%.6f' % (end_time_s-start_time_s)}, " # total
      QaServer.config.performance_tracker.write "#{full_results[:performance][:fetched_bytes]}, " # data size
      QaServer.config.performance_tracker.puts "#{authority_name}" # authority name
      QaServer.config.performance_tracker.flush
    end
end
