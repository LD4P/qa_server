require 'rails/generators'

class QaServer::ConfigGenerator < Rails::Generators::Base
  desc """
    This generator installs the qa_server configuration files into your application for:
    * authority configs
    * authority scenarios
    * i18n
       """

  source_root File.expand_path('../templates', __FILE__)

  def authority_configs
    directory "config/authorities/linked_data", recursive: false
  end

  def authority_scenarios
    directory "config/authorities/linked_data/scenarios", recursive: false
  end

  def inject_i18n
    copy_file 'config/locales/qa_server.en.yml'
  end
end
