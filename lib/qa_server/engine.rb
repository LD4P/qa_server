module QaServer
  class Engine < ::Rails::Engine
    isolate_namespace QaServer
  end
end
