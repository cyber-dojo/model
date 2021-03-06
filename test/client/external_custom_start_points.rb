# frozen_string_literal: true
require_relative '../require_source'
require_source 'http_json_hash/service'
require_source 'external_http'

class ExternalCustomStartPoints

  def initialize(http = ExternalHttp.new)
    @http = HttpJsonHash::service(self.class.name, http, 'custom-start-points', 4526)
  end

  def display_names
    @http.get(:names, {})
  end

  def manifest(display_name)
    @http.get(__method__, { name:display_name })
  end

end
