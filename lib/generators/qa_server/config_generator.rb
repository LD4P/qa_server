require 'rails/generators'

class Hyrax::ConfigGenerator < Rails::Generators::Base
  desc """
    This generator installs the hyrax configuration files into your application for:
    * authority configs
    * authority scenarios
    * i18n
       """

  source_root File.expand_path('../templates', __FILE__)

  def authority_configs
    directory "config/authorities/linked_data", recursive: false
  end

  def authority_scenarios
    directory "config/authorities/linked_data", recursive: false
  end

  # def simple_form_initializers
  #   copy_file 'config/initializers/simple_form.rb'
  #   copy_file 'config/initializers/simple_form_bootstrap.rb'
  # end

  # def create_initializer_config_file
  #   copy_file 'config/initializers/qa_server.rb'
  # end

  def inject_i18n
    copy_file 'config/locales/qa_server.en.yml'
  end
end
