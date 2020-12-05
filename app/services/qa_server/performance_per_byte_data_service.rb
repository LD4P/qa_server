# frozen_string_literal: true
# This class calculates performance stats based on size of data.
module QaServer
  class PerformancePerByteDataService
    class << self
      include QaServer::PerformanceHistoryDataKeys

      class_attribute :stats_calculator_class, :performance_data_class
      self.stats_calculator_class = QaServer::PerformancePerByteCalculatorService
      self.performance_data_class = QaServer::PerformanceHistory

      # Performance data based on size of data.
      # @param authority_name [String] name of an authority
      # @param action [Symbol] :search, :fetch, or :all_actions
      # @param n [Integer] calculate stats for last n records
      # @returns [Hash] performance statistics based on size of data
      # @example returns for n=2
      #   { data_raw_bytes_from_source: [16271, 16271],
      #     retrieve_bytes_per_ms: [67.24433786890475, 55.51210410757532],
      #     retrieve_ms_per_byte: [0.014871140555351083, 0.018014089288745542]
      #     graph_load_bytes_per_ms_ms: [86.74089418722461, 54.97464153778724],
      #     graph_load_ms_per_byte: [0.011528587632974647, 0.018190205011389522],
      #     normalization_bytes_per_ms: [64.70169466560836, 89.25337465693322],
      #     normalization_ms_per_byte: [0.01530700843338457, 0.015455545718983178]
      #   }
      def calculate(authority_name:, action:, n: 10)
        records = records_by(authority_name, action)
        stats_calculator_class.new(records: records, n: n).calculate
      end

    private

      def records_by(authority_name, action)
        where_clause = {}
        where_clause[:authority] = authority_name unless authority_name.nil? || authority_name == ALL_AUTH
        where_clause[:action] = action unless action.nil? || action == ALL_ACTIONS
        performance_data_class.where(where_clause)
      end
    end
  end
end
