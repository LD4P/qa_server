# frozen_string_literal: true
# This module sets up the keys used to identify data in Rails.cache
module QaServer
  class PerformanceHourlyGraphCache
    class_attribute :authority_list_class
    self.authority_list_class = QaServer::AuthorityListerService

    class << self
      include QaServer::PerformanceHistoryDataKeys

      # Generates graphs for the past 24 hours for :search, :fetch, and :all actions for each authority.
      def generate_graphs(force: false)
        QaServer.config.monitor_logger.debug("(QaServer::PerformanceHourlyGraphCache) - GENERATING hourly performance graphs")
        QaServer.config.performance_cache.write_all
        generate_graphs_for_authorities(force: force)
      end

      private

        def generate_graphs_for_authorities(force:)
          auths = authority_list_class.authorities_list
          generate_graphs_for_authority(authority_name: ALL_AUTH, force: force) # generates graph for all authorities
          auths.each { |authname| generate_graphs_for_authority(authority_name: authname, force: force) }
        end

        def generate_graphs_for_authority(authority_name:, force:)
          [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
            hash[action] = geneate_24_hour_graph(authority_name: authority_name, action: action, force: force)
          end
        end

        def geneate_24_hour_graph(authority_name:, action:, force:)
          graph_created = false
          data = Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                                   expires_in: QaServer::TimeService.current_time.end_of_hour - QaServer::TimeService.current_time,
                                   race_condition_ttl: 1.hour, force: force) do
            data = QaServer::PerformanceGraphDataService.calculate_last_24_hours(authority_name: authority_name, action: action)
            QaServer::PerformanceGraphingService.generate_hourly_graph(authority_name: authority_name, action: action, data: data)
            graph_created = true
            data
          end
          regen_last_hour(authority_name: authority_name, action: action, data: data) unless graph_created
        end

        def regen_last_hour_and_graph(authority_name:, action:, data:)
          Rails.cache.fetch(cache_key_for_authority_action(authority_name: authority_name, action: action),
                            expires_in: QaServer::TimeService.current_time.end_of_hour - QaServer::TimeService.current_time,
                            race_condition_ttl: 1.hour, force: true) do
            data = QaServer::PerformanceGraphDataService.recalculate_last_hour(authority_name: authority_name, action: action, averages: data)
            QaServer::PerformanceGraphingService.generate_hourly_graph(authority_name: authority_name, action: action, data: data)
            data
          end
        end

        def cache_key_for_authority_action(authority_name:, action:)
          "QaServer::CacheKeys::PERFORMANCE_GRAPH_HOURLY_DATA-#{authority_name || ''}-#{action}"
        end
    end
  end
end
