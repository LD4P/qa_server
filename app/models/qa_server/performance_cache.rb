# frozen_string_literal: true
# Model to hold performance data in memory and ultimately write it out to the database
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

    def destroy(id)
      @cache.delete(id)
    end

    def write_all
      size_before = @cache.size
      @cache.each do |id, entry|
        next if incomplete? entry
        QaServer::PerformanceHistory.create(dt_stamp: entry[:dt_stamp], authority: entry[:authority],
                                            action: entry[:action], action_time_ms: entry[:action_time_ms],
                                            size_bytes: entry[:size_bytes], retrieve_time_ms: entry[:retrieve_time_ms],
                                            graph_load_time_ms: entry[:graph_load_time_ms],
                                            normalization_time_ms: entry[:normalization_time_ms])
        @cache.delete(id)
      end
      log_write_all("(#{self.class}##{__method__})", size_before, @cache.size)
    end

    def log(id:)
      return if QaServer.config.suppress_logging_performance_datails
      Rails.logger.debug("*** performance data for id: #{id} ***")
      Rails.logger.debug(@cache[id].to_yaml)
    end

    private

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
          QaServer.config.monitor_logger.warn("#{prefix} 0 of #{size_before} performance data records were saved") if size_before == cache_size
          QaServer.config.monitor_logger.info("#{prefix} #{size_before - cache_size} of #{size_before} performance data records were saved") if size_before > cache_size
        else
          QaServer.config.monitor_logger.info("#{prefix} 0 of 0 performance data records were saved")
        end
      end
  end
end
