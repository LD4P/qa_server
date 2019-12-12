# frozen_string_literal: true
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

  def self.current_time
    Time.now.in_time_zone(QaServer.config.preferred_time_zone_name)
  end

  def self.current_time_s
    current_time.to_f
  end
end
