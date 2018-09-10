# frozen_string_literal: true
namespace :qa_server do
  namespace :install do
    desc 'Copy migrations from QaServer to application'
    task migrations: :environment do
      QaServer::DatabaseMigrator.copy
    end
  end
end
