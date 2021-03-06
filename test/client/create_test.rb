# frozen_string_literal: true
require_relative 'test_base'

class CreateTest < TestBase

  def self.id58_prefix
    'f26'
  end

  def id58_setup
    @display_name = custom_start_points.display_names.sample
    @custom_manifest = custom_start_points.manifest(display_name)
  end

  attr_reader :display_name, :custom_manifest

  # - - - - - - - - - - - - - - - - -

  test 'q31', %w(
  |POST /group_create(manifest)
  |has status 200
  |returns the id: of a new group
  |that exists in saver
  |whose manifest matches the display_name
  ) do
    manifests = [custom_manifest]
    options = default_options
    id = model.group_create(manifests, options)
    assert model.group_exists?(id), :group_exists?
    m = model.group_manifest(id)
    assert_equal display_name, m['display_name'], :display_name
  end

  # - - - - - - - - - - - - - - - - -

  test 'q32', %w(
  |POST /kata_create(manifest)
  |has status 200
  |returns the id: of a new kata
  |that exists in saver
  |whose manifest matches the display_name
  ) do
    manifest = custom_manifest
    options = default_options
    id = model.kata_create(manifest, options)
    assert model.kata_exists?(id), :group_exists?
    m = model.kata_manifest(id)
    assert_equal display_name, m['display_name'], :display_name
  end

end
