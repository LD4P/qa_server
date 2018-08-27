require 'rails/generators'

class QaServer::AssetsGenerator < Rails::Generators::Base
  desc """
    This generator installs the qa_server CSS assets into your application
       """

  source_root File.expand_path('../templates', __FILE__)

  def inject_css
    copy_file "qa_server.scss", "app/assets/stylesheets/qa_server.scss"
  end

  def inject_js
    return if qa_server_javascript_installed?
    insert_into_file 'app/assets/javascripts/application.js', after: '//= require_tree .' do
      <<-JS.strip_heredoc

        //= require qa_server
      JS
    end
  end

  # def copy_image_file
  #   copy_file 'app/assets/images/unauthorized.png'
  # end

  private

    def qa_server_javascript_installed?
      IO.read("app/assets/javascripts/application.js").include?('qa_server')
    end
end
