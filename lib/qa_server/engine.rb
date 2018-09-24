# frozen_string_literal: true
module QaServer
  class Engine < ::Rails::Engine
    isolate_namespace QaServer

    require 'qa'

    def self.engine_mount
      QaServer::Engine.routes.find_script_name({})
    end

    def self.qa_engine_mount
      Qa::Engine.routes.find_script_name({})
    end

    # Force these models to be added to Legato's registry in development mode
    config.eager_load_paths += %W[
      #{config.root}/app/models/qa_server/download.rb
      #{config.root}/app/models/qa_server/pageview.rb
    ]

    initializer 'qa_server.assets.precompile' do |app|
      app.config.assets.paths << config.root.join('vendor', 'assets', 'fonts')
      app.config.assets.paths << config.root.join('app', 'assets', 'images')
      app.config.assets.precompile += %w[*.png *.jpg *.ico *.gif *.svg]
    end
  end
end
