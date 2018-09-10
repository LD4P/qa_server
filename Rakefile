# frozen_string_literal: true
# !/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

# Set up the test application prior to running jasmine tasks.
task :setup_test_server do
  require 'engine_cart'
  EngineCart.load_application!
end

Dir.glob('tasks/*.rake').each { |r| import r }

task default: :ci
