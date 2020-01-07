# frozen_string_literal: true
require 'qa_server/engine'
require 'qa_server/version'
require 'user_agent'
require 'deprecation'

module QaServer
  extend ActiveSupport::Autoload
  extend Deprecation

  self.deprecation_horizon = 'LD4P/QaServer v6.0.0'

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

  # @return [ActiveSupport::TimeWithZone] current DateTime in the configured preferred_time_zone_name
  def self.current_time
    Time.now.in_time_zone(QaServer.config.preferred_time_zone_name)
  end

  # @return [Float] current DateTime in seconds
  def self.current_time_s
    current_time.to_f
  end

  # @return [ActiveSupport::TimeWithZone] DateTime at which cache should expire
  def self.monitoring_expires_at
    offset = QaServer.config.hour_offset_to_expire_cache
    offset_time = current_time
    offset_time = offset_time.tomorrow unless (offset_time + 5.minutes).hour < offset
    offset_time.beginning_of_day + offset.hours - 5.minutes
  end

  # @return [Float] number of seconds until cache should expire
  def self.cache_expiry
    monitoring_expires_at - current_time
  end

  def self.log_agent_info(request)
    return if !Qa.config.respond_to?(:suppress_ip_data_from_log) || Qa.config.suppress_ip_data_from_log
    user_agent = request.respond_to?(:user_agent) && !request.user_agent.nil? ? ::UserAgent.parse(request.user_agent) : nil
    return Rails.logger.info("{browser: UNKNOWN, browser_version: UNKNOWN, platform: UNKNOWN, os: UNKNOWN}") if user_agent.nil?
    browser = user_agent.browser
    browser_version = user_agent.version
    platform = user_agent.platform
    os = user_agent.os
    Rails.logger.info("{browser: #{browser}, browser_version: #{browser_version}, platform: #{platform}, os: #{os}}")
  end
end
