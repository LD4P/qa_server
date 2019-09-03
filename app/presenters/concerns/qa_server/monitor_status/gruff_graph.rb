# frozen_string_literal: true
require 'fileutils'
require 'gruff'

# This module include provides graph methods used by all monitor status presenters working with graphs
module QaServer::MonitorStatus
  module GruffGraph
    private

      def graph_relative_path
        File.join('qa_server', 'charts')
      end

      def graph_full_path(graph_filename)
        path = Rails.root.join('app', 'assets', 'images', graph_relative_path)
        FileUtils.mkdir_p path
        File.join(path, graph_filename)
      end
  end
end
# frozen_string_literal: true
