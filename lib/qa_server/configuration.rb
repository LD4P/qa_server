# frozen_string_literal: true
module QaServer
  class Configuration
    attr_writer :qa_engine_mount_path
    def qa_engine_mount_path
      @qa_engine_mount_path ||= 'authorities'
    end
  end
end
