class QaServer::ModelsGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  desc 'This generator makes the following changes to your application:
      1. Copies database migrations'

  def banner
    say_status('info', 'GENERATING QA SERVER MODELS', :blue)
  end

  # Setup the database migrations
  def copy_migrations
    rake 'qa_server:install:migrations'
  end
end
