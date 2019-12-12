# frozen_string_literal: true
require 'rails/generators'

class QaServer::ConfigGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
    This generator installs the qa_server configuration files into your application for:
    * authority configs
    * authority scenarios
    * i18n
    * add default configuration initializer
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

  def create_initializer_config_file
    copy_file 'config/initializers/qa_server.rb'
  end

  def append_prepends
    inject_into_file 'config/application.rb', after: /Rails::Application/ do
      "\n      config.to_prepare do"\
      "\n        Qa::Authorities::LinkedData::FindTerm.prepend PrependedLinkedData::FindTerm"\
      "\n        Qa::Authorities::LinkedData::SearchQuery.prepend PrependedLinkedData::SearchQuery"\
      "\n        Qa::LinkedData::GraphService.prepend PrependedServices::GraphService"\
      "\n        RDF::Graph.prepend PrependedRdf::RdfGraph"\
      "\n      end\n"
    end
  end
end
