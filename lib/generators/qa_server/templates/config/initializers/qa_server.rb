# frozen_string_literal: true
QaServer.config do |config|
  # Configure where you mounted the Qa engine so URLs will be generated with the correct path.
  # As defined in config/routes.rb as `mount Qa::Engine => '/authorities'`
  # config.qa_engine_mount_path = 'authorities'
end
