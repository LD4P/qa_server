# frozen_string_literal: true
# This module sets up the keys used to identify data in Rails.cache
module QaServer
  module CacheKeys
    RUN_SUMMARY_DATA_CACHE_KEY = "QaServer--CacheKeys--run_summary_data"
    RUN_HISTORY_DATA_CACHE_KEY = "QaServer--CacheKeys--run_history_data"

    PERFORMANCE_DATATABLE_DATA_CACHE_KEY = "QaServer--Cache--performance_datatable_data"
    PERFORMANCE_GRAPH_HOURLY_DATA_CACHE_KEY = "QaServer--CacheKeys--performance_graph_hourly_data"
    PERFORMANCE_GRAPH_DAILY_DATA_CACHE_KEY = "QaServer--CacheKeys--performance_graph_daily_data"
    PERFORMANCE_GRAPH_MONTHLY_DATA_CACHE_KEY = "QaServer--CacheKeys--performance_graph_monthly_data"
  end
end
