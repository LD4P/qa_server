# frozen_string_literal: true
module PrependedServices::GraphService
  # Override Qa::LinkedData::GraphService#process_error method
  def process_error(e, url)
    Rails.logger.warn("******** RDF::Graph#load failure: exception=#{e.inspect}")
    super
  end
end
