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
  def load(url, graph_name: nil, **options)
    raise TypeError.new("#{self} is immutable") if immutable?

    start_time_s = Time.now.to_f

    reader = RDF::Reader.open(url, {base_uri: url}.merge(options))

    end_time_s = Time.now.to_f
    QaServer.config.performance_tracker.write "#{'%.6f' % (end_time_s-start_time_s)}, " # read data

    start_time_s = Time.now.to_f

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

    end_time_s = Time.now.to_f
    QaServer.config.performance_tracker.write "#{'%.6f' % (end_time_s-start_time_s)}, " # load graph
  end
end
