# frozen_string_literal: true
# Model to hold performance data in memory and ultimately write it out to the database
require 'objspace'

module QaServer
  class PerformanceCache
    def initialize
      @cache = {}
    end

    def new_entry(authority:, action:)
      entry = { dt_stamp: QaServer::TimeService.current_time,
                authority: authority,
                action: action }
      id = SecureRandom.uuid
      @cache[id] = entry
      id
    end

    def update(id:, updates: {})
      return false unless id && @cache.key?(id)
      entry = @cache[id]
      @cache[id] = entry.merge(updates)
    end

    def complete_entry(id:)
      log(id: id)
      QaServer.config.performance_cache_logger.debug("#{self.class}##{__method__} - id: #{id}   cache memory: #{ObjectSpace.memsize_of @cache}")
      write_all if ObjectSpace.memsize_of(@cache) > QaServer.config.max_performance_cache_size
    end

    def destroy(id)
      @cache.delete(id) # WARNING: doesn't change the size of the cache
    end

    def write_all
      cache_to_write = swap_cache_hash
      size_before = cache_to_write.size
      cache_to_write.each do |id, entry|
        next if incomplete? entry
        QaServer::PerformanceHistory.create(dt_stamp: entry[:dt_stamp], authority: entry[:authority],
                                            action: entry[:action], action_time_ms: entry[:action_time_ms],
                                            size_bytes: entry[:size_bytes], retrieve_time_ms: entry[:retrieve_time_ms],
                                            graph_load_time_ms: entry[:graph_load_time_ms],
                                            normalization_time_ms: entry[:normalization_time_ms])
        cache_to_write.delete(id)
      end
      log_write_all("(#{self.class}##{__method__})", size_before, cache_to_write.size)
      cache_to_write = nil # free cache for garbage collection
    end

    private

      def swap_cache_hash
        cache_to_write = @cache
        @cache = {} # reset main cache so new items after write begins are cached in the main cache
        QaServer.config.performance_cache_logger.debug("#{self.class}##{__method__} - cache memory BEFORE write: #{ObjectSpace.memsize_of(cache_to_write)}")
        cache_to_write
      end

      def log(id:)
        return if QaServer.config.suppress_logging_performance_datails?
        Rails.logger.debug("*** performance data for id: #{id} ***")
        Rails.logger.debug(@cache[id].to_yaml)
      end

      def incomplete?(entry)
        required_keys.each { |k| return true unless entry.key? k }
        false
      end

      def required_keys
        [:dt_stamp,
         :authority,
         :action,
         :action_time_ms,
         :size_bytes,
         :retrieve_time_ms,
         :graph_load_time_ms,
         :normalization_time_ms]
      end

      def log_write_all(prefix, size_before, cache_size)
        if size_before.positive?
          QaServer.config.performance_cache_logger.debug("#{prefix} 0 of #{size_before} performance data records were saved") if size_before == cache_size
          QaServer.config.performance_cache_logger.debug("#{prefix} #{size_before - cache_size} of #{size_before} performance data records were saved") if size_before > cache_size
        else
          QaServer.config.performance_cache_logger.debug("#{prefix} 0 of 0 performance data records were saved")
        end
        QaServer.config.performance_cache_logger.debug("#{prefix} - cache memory AFTER write: #{ObjectSpace.memsize_of @cache}")
      end
  end
end
