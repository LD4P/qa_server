# frozen_string_literal: true
# Maintain a cache of data for the Performance Datatable
module QaServer
  class PerformanceDatatableCache
    include QaServer::CacheKeys

    class_attribute :performance_data_service
    self.performance_data_service = QaServer::PerformanceDatatableService

    # Retrieve performance datatable data from the cache
    # @param force [Boolean] if true, calculate the stats even if the cache hasn't expired; otherwise, use cache if not expired
    # @returns [Hash] performance statistics for configured time period by action for each authority
    # @example
    #   { all_authorities:
    #     { search:
    #       { retrieve_avg_ms: 12.3, graph_load_avg_ms: 2.1, normalization_avg_ms: 4.2, full_request_avg_ms: 16.5,
    #         retrieve_10th_ms: 12.3, graph_load_10th_ms: 12.3, normalization_10th_ms: 4.2, full_request_10th_ms: 16.5,
    #         retrieve_90th_ms: 12.3, graph_load_90th_ms: 12.3, normalization_90th_ms: 4.2, full_request_90th_ms: 16.5 },
    #       fetch: { ... # same data as for search_stats },
    #       all: { ... # same data as for search_stats }
    #     },
    #     AGROVOC_LD4L_CACHE: { ... # same data for each authority  }
    #   }
    def self.data(force: false)
      Rails.cache.fetch(PERFORMANCE_DATATABLE_DATA_CACHE_KEY,
                        expires_in: QaServer::CacheExpiryService.cache_expiry,
                        race_condition_ttl: 5.minutes, force: force) do
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceDatatableCache) - CALCULATING performance datatable stats (force: #{force})")
        performance_data_service.calculate_datatable_data
      end
    end
  end
end
