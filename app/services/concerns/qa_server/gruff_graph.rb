# frozen_string_literal: true
require 'fileutils'
require 'gruff'

# This module include provides graph methods for generating graphs with Gruff
module QaServer
  module GruffGraph
  private

    # common path for displaying and writing
    def graph_relative_path
      File.join('qa_server', 'charts')
    end

    # used for displaying in a view with <image> tag
    def graph_image_path
      File.join('/', graph_relative_path)
    end

    # used for writing out the file
    def graph_full_path(graph_filename)
      path = Rails.root.join('public', graph_relative_path)
      # path = Rails.root.join('app', 'assets', 'images', graph_relative_path)
      FileUtils.mkdir_p path
      File.join(path, graph_filename)
    end
  end
end
