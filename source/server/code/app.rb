# frozen_string_literal: true
require_relative 'app_base'
require_relative 'model'
require_relative 'probe'

class App < AppBase

  def initialize(externals)
    super(externals)
  end

   get_json(:alive?, Probe)
   get_json(:ready?, Probe)
   get_json(:sha,    Probe)

   get_json(:group_exists?,  Model)
  post_json(:group_create,   Model)
   get_json(:group_manifest, Model)

   get_json(:kata_exists?,   Model)
  post_json(:kata_create,    Model)
   get_json(:kata_manifest,  Model)

end
