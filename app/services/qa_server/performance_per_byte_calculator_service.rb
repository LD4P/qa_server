# frozen_string_literal: true
# This class calculates min, max, average stats for load, normalization, and full request times for a given set of performance records.
require 'matrix'
module QaServer
  class PerformancePerByteCalculatorService
    include QaServer::PerformanceHistoryDataKeys

    TIME  = 0
    BYTES = 1

    attr_reader :n, :stats, :records

    # @param records [Array <Qa::PerformanceHistory>] set of records used to calculate the statistics
    def initialize(records:, n:)
      @records = records
      @n = n
      @stats = {}
    end

    # Calculate performance statistics with percentiles.  Min is at the 10th percentile.  Max is at the 90th percentile.
    # @return [Hash] hash of the statistics
    # @example
    #   { data_raw_bytes_from_source: [16271, 16271],
    #     retrieve_bytes_per_ms: [67.24433786890475, 55.51210410757532],
    #     retrieve_ms_per_byte: [0.014871140555351083, 0.018014089288745542]
    #     graph_load_bytes_per_ms_ms: [86.74089418722461, 54.97464153778724],
    #     graph_load_ms_per_byte: [0.011528587632974647, 0.018190205011389522],
    #     normalization_bytes_per_ms: [64.70169466560836, 89.25337465693322],
    #     normalization_ms_per_byte: [0.01530700843338457, 0.015455545718983178]
    #   }
    def calculate
      extract_bytes
      calculate_retrieve_stats
      calculate_graph_load_stats
      calculate_normalization_stats
      stats
    end

    private

      def extract_bytes
        stats[SRC_BYTES] = retrieve_data.count.zero? ? 0 : retrieve_data.map { |d| d[BYTES] }
      end

      def calculate_retrieve_stats
        stats[BPMS_RETR] = calculate_bytes_per_ms(retrieve_data)
        stats[MSPB_RETR] = calculate_ms_per_byte(retrieve_data)
      end

      def calculate_graph_load_stats
        stats[BPMS_GRPH] = calculate_bytes_per_ms(graph_load_data)
        stats[MSPB_GRPH] = calculate_ms_per_byte(graph_load_data)
      end

      def calculate_normalization_stats
        stats[BPMS_NORM] = calculate_bytes_per_ms(norm_data)
        stats[MSPB_NORM] = calculate_ms_per_byte(norm_data)
      end

      def calculate_bytes_per_ms(data)
        return 0 if data.count.zero?
        return data[0][BYTES] / d[0][TIME] if data.count == 1
        data.map { |d| d[BYTES] / d[TIME] }
      end

      def calculate_ms_per_byte(data)
        return 0 if data.count.zero?
        return data[0][TIME] / d[0][BYTES] if data.count == 1
        data.map { |d| d[TIME] / d[BYTES] }
      end

      def data(column)
        records.where.not(column => nil).order(dt_stamp: :desc).limit(n).pluck(column, :size_bytes)
      end

      def retrieve_data
        @retrieve_data ||= data(:retrieve_time_ms)
      end

      def graph_load_data
        @graph_data ||= data(:graph_load_time_ms)
      end

      def norm_data
        @norm_data ||= data(:normalization_time_ms)
      end
  end
end
