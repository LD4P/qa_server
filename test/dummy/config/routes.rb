Rails.application.routes.draw do
  mount QaServer::Engine => "/qa_server"
end
