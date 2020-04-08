# frozen_string_literal: true
# This module sets up the keys used to identify data in Rails.cache
module QaServer
  module CacheKeys
    SCENARIO_RUN_SUMMARY_DATA_CACHE_KEY = "QaServer--CacheKeys--scenario_run_summary_data"
    SCENARIO_RUN_FAILURE_DATA_CACHE_KEY = "QaServer--CacheKeys--scenario_run_failure_data"
    SCENARIO_RUN_HISTORY_DATA_CACHE_KEY = "QaServer--CacheKeys--scenario_run_history_data"

    PERFORMANCE_DATATABLE_DATA_CACHE_KEY = "QaServer--Cache--performance_datatable_data"
    PERFORMANCE_GRAPH_HOURLY_DATA_CACHE_KEY = "QaServer--CacheKeys--performance_graph_hourly_data"
  end
end
