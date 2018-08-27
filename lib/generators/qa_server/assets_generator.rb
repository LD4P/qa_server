require 'rails/generators'

class QaServer::AssetsGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
    This generator installs the qa_server CSS assets into your application
       """

  def banner
    say_status('info', 'GENERATING QA_SERVER ASSETS', :blue)
  end

  def inject_css
    say_status('info', '  -- adding qa_server css', :blue)
    copy_file "qa_server.scss", "app/assets/stylesheets/qa_server.scss"
  end

  def inject_js
    return if qa_server_javascript_installed?
    say_status('info', '  -- adding qa_server javascript', :blue)
    insert_into_file 'app/assets/javascripts/application.js', after: '//= require_tree .' do
      <<-JS.strip_heredoc

        //= require qa_server
      JS
    end
  end

  private

    def qa_server_javascript_installed?
      IO.read("app/assets/javascripts/application.js").include?('qa_server')
    end
end
