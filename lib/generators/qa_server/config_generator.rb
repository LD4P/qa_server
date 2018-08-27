require 'rails/generators'

class QaServer::ConfigGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
    This generator installs the qa_server configuration files into your application for:
    * authority configs
    * authority scenarios
    * i18n
       """

  def banner
    say_status('info', 'INSTALLING QA_SERVER CONFIGURATIONS', :blue)
  end

  def authority_configs
    say_status('info', '  -- adding authority configurations', :blue)
    directory "config/authorities/linked_data", recursive: false
  end

  def authority_scenarios
    say_status('info', '  -- adding authority validations', :blue)
    directory "config/authorities/linked_data/scenarios", recursive: false
  end

  def inject_i18n
    say_status('info', '  -- adding i18n translations', :blue)
    copy_file 'config/locales/qa_server.en.yml'
  end
end
