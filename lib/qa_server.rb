require 'qa_server/engine'
require 'qa_server/version'

module QaServer
  extend ActiveSupport::Autoload

  autoload :Configuration

  # @api public
  #
  # Exposes the Questioning Authority configuration
  #
  # @yield [Qa::Configuration] if a block is passed
  # @return [Qa::Configuration]
  # @see Qa::Configuration for configuration options
  def self.config(&block)
    @config ||= QaServer::Configuration.new

    yield @config if block

    @config
  end
end
