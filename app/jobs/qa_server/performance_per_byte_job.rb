# frozen_string_literal: true
# Job to generate the performance day graph covering the last 24 hours.
module QaServer
  class PerformancePerByteJob < ApplicationJob
    include QaServer::PerformanceHistoryDataKeys

    queue_as :default

    class_attribute :authority_list_class, :data_service
    self.authority_list_class = QaServer::AuthorityListerService
    self.data_service = QaServer::PerformancePerByteDataService
    # self.graphing_service = QaServer::PerformanceGraphingService

    def perform(n: 10, action: :search, authority_complexity_ratings: {})
      # checking active_job_id? prevents race conditions for long running jobs
      generate_data_for_authorities(n, action, authority_complexity_ratings) if QaServer::JobIdCache.active_job_id?(job_key: job_key, job_id: job_id)
    end

    private

      def generate_data_for_authorities(n, action, authority_complexity_ratings)
        QaServer.config.monitor_logger.debug("(#{self.class}-#{job_id}) - GENERATING performance by byte data")
        auths = authority_list_class.authorities_list
        data = if action.nil?
                 # generate_data_for_authority(ALL_AUTH, n) # generates data for all authorities
                 auths.each_with_object({}) { |authname, hash| hash[authname] = generate_data_for_authority(authname, n) }
               else
                 auths.each_with_object({}) { |authname, hash| hash[authname] = { action => generate_data(authname, action, n) } }
               end
        QaServer.config.monitor_logger.debug("(#{self.class}-#{job_id}) COMPLETED performance by byte data generation")
        QaServer::JobIdCache.reset_job_id(job_key: job_key)
        convert_to_csv(data, authority_complexity_ratings)
      end

      def generate_data_for_authority(authority_name, n)
        [SEARCH, FETCH, ALL_ACTIONS].each_with_object({}) do |action, hash|
          hash[action] = generate_data(authority_name, action, n)
        end
      end

      def generate_data(authority_name, action, n)
        data_service.calculate(authority_name: authority_name, action: action, n: n)
        # graphing_service.generate_day_graph(authority_name: authority_name, action: action, data: data)
      end

      # @param data [Hash] performance statistics based on size of data
      # @param authority_complexity_ratings [Hash] complexity rating of the extended context included with results
      # @example data
      #   { data_raw_bytes_from_source: [16271, 16271],
      #     retrieve_bytes_per_ms: [67.24433786890475, 55.51210410757532],
      #     retrieve_ms_per_byte: [0.014871140555351083, 0.018014089288745542]
      #     graph_load_bytes_per_ms_ms: [86.74089418722461, 54.97464153778724],
      #     graph_load_ms_per_byte: [0.011528587632974647, 0.018190205011389522],
      #     normalization_bytes_per_ms: [64.70169466560836, 89.25337465693322],
      #     normalization_ms_per_byte: [0.01530700843338457, 0.015455545718983178]
      #   }
      def convert_to_csv(data, authority_complexity_ratings) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        performance_file = File.new('log/performance.csv', 'w')
        performance_file.write("authority name, complexity_rating, action, size_bytes, ")
        performance_file.write("retrieve_bytes_per_ms, graph_load_bytes_per_ms, normalize_bytes_per_ms, ")
        performance_file.puts("retrieve_ms_per_byte, graph_load_ms_per_byte, normalize_ms_per_byte")
        data.each do |auth_name, auth_data|
          complexity_rating = authority_complexity_ratings.key?(auth_name) ? authority_complexity_ratings[auth_name] : "UNKNOWN"
          auth_data.each do |action, action_data|
            auth_action = "#{auth_name}, #{complexity_rating}, #{action}"
            0.upto(action_data[:retrieve_bytes_per_ms].size - 1) do |idx|
              performance_file.write(auth_action)
              performance_file.write(", #{action_data[SRC_BYTES][idx]}")
              performance_file.write(", #{action_data[BPMS_RETR][idx]}")
              performance_file.write(", #{action_data[BPMS_GRPH][idx]}")
              performance_file.write(", #{action_data[BPMS_NORM][idx]}")
              performance_file.write(", #{action_data[MSPB_RETR][idx]}")
              performance_file.write(", #{action_data[MSPB_GRPH][idx]}")
              performance_file.puts(", #{action_data[MSPB_NORM][idx]}")
            end
          end
        end
        performance_file.close
      end

      def job_key
        "QaServer::PerformanceByByteJob--job_id"
      end
  end
end
