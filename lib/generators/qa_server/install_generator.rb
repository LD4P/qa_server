# frozen_string_literal: true
module QaServer
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc """
  This generator makes the following changes to your application:
  1. Runs qa_server:models:install
  2. Injects QaServer routes
  3. Installs qa_server assets
         """

    def banner
      say_status('info', 'INSTALLING QA_SERVER', :blue)
    end

    def run_required_generators
      generate "qa_server:assets"
      generate "qa_server:config"
      generate "qa_server:models#{options[:force] ? ' -f' : ''}"
    end

    def add_to_gemfile
      say_status('info', '  -- adding qa_server required gems', :blue)
      gem 'linkeddata'

      Bundler.with_clean_env do
        run "bundle install"
      end
    end

    # The engine routes have to come after the devise routes so that /users/sign_in will work
    def inject_routes
      say_status('info', '  -- adding qa_server routes', :blue)

      # # Remove root route that was added by blacklight generator
      # gsub_file 'config/routes.rb', /root (:to =>|to:) "catalog#index"/, ''

      inject_into_file 'config/routes.rb', after: /Rails.application.routes.draw do\n/ do
        "  mount Qa::Engine => '/authorities'\n"\
        "  mount QaServer::Engine, at: '/'\n"\
        "  resources :welcome, only: 'index'\n"\
        "  root 'qa_server/homepage#index'\n"
      end
    end

    def inject_bootstrap
      say_status('info', '  -- adding bootstrap resources', :blue)

      inject_into_file 'app/views/layouts/application.html.erb', after: /<head>\n/ do
        "    <!-- Latest compiled and minified CSS -->\n"\
        "    <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css'>\n"\
        "    <!-- jQuery library -->\n"\
        "    <script src='https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js'></script>\n"\
        "    <!-- Latest compiled JavaScript -->\n"\
        "    <script src='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js'></script>\n"
      end
    end

    def create_location_for_charts
      say_status('info', '  -- creating directory to hold dynamically generated charts', :blue)
      copy_file 'app/assets/images/qa_server/charts/.keep'
    end
  end
end
