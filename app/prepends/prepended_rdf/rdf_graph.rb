# frozen_string_literal: true
require 'rdf/reader'

module PrependedRdf::RdfGraph
  ##
  # Loads RDF statements from the given file or URL into `self`.
  #
  # @param  [String, #to_s]          url
  # @param  [Hash{Symbol => Object}] options
  #   Options from {RDF::Reader.open}
  # @option options [RDF::Resource] :graph_name
  #   Set set graph name of each loaded statement
  # @return [void]
  def load(url, graph_name: nil, **options) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    return super if QaServer.config.suppress_performance_gathering

    raise TypeError, "#{self} is immutable" if immutable?
    phid, real_url = parse_phid(url)
    performance_udpates = {}
    start_time_s = QaServer::TimeService.current_time_s

    reader = RDF::Reader.open(real_url, { base_uri: real_url }.merge(options))

    end_time_s = QaServer::TimeService.current_time_s
    performance_udpates[:retrieve_time_ms] = (end_time_s - start_time_s) * 1000
    QaServer.config.performance_tracker.write "#{format('%.6f', end_time_s - start_time_s)}, " # read data

    start_time_s = QaServer::TimeService.current_time_s

    if graph_name
      statements = []
      reader.each_statement do |statement|
        statement.graph_name = graph_name
        statements << statement
      end
      insert_statements(statements)
      statements.size
    else
      insert_statements(reader)
      nil
    end

    end_time_s = QaServer::TimeService.current_time_s
    performance_udpates[:graph_load_time_ms] = (end_time_s - start_time_s) * 1000
    QaServer.config.performance_cache.update(id: phid, updates: performance_udpates)
    QaServer.config.performance_tracker.write "#{format('%.6f', end_time_s - start_time_s)}, " # load graph
  end

  private

    def parse_phid(url)
      i = url.rindex('&phid=')
      phid = url[(i + 6)..url.length]
      adjusted_url = url[0..(i - 1)]
      [phid, adjusted_url]
    end
end
