# frozen_string_literal: true
require_relative 'creator_test_base'

class CreateTest < CreatorTestBase

  def self.id58_prefix
    '26F'
  end

  def id58_setup
    @display_name = any_custom_start_points_display_name
    @exercise_name = any_exercises_start_points_display_name
    @language_name = any_languages_start_points_display_name
  end

  attr_reader :display_name, :exercise_name, :language_name

  # - - - - - - - - - - - - - - - - -
  # new API
  # - - - - - - - - - - - - - - - - -

  test '702',
  %w( group_create_custom returns the id of a newly created group ) do
    id = creator.group_create_custom([display_name])
    assert group_exists?(id), id
    manifest = group_manifest(id)
    assert_equal display_name, manifest['display_name']
  end

  # - - - - - - - - - - - - - - - - -

  test '703',
  %w( kata_create_custom returns the id of a newly created kata ) do
    id = creator.kata_create_custom(display_name)
    assert kata_exists?(id), id
    manifest = kata_manifest(id)
    assert_equal display_name, manifest['display_name']
  end

  # - - - - - - - - - - - - - - - - -

  test '602',
  %w( group_create returns the id of a newly created group ) do
    id = creator.group_create(exercise_name, [language_name])
    assert group_exists?(id), id
    manifest = group_manifest(id)
    assert_equal language_name, manifest['display_name']
    assert_equal exercise_name, manifest['exercise']
  end

  # - - - - - - - - - - - - - - - - -

  test '603',
  %w( kata_create returns the id of a newly created kata ) do
    id = creator.kata_create(exercise_name, language_name)
    assert kata_exists?(id), id
    manifest = kata_manifest(id)
    assert_equal language_name, manifest['display_name']
    assert_equal exercise_name, manifest['exercise']
  end

  # - - - - - - - - - - - - - - - - -
  # old API (deprecated)
  # - - - - - - - - - - - - - - - - -

  test '802',
  %w( deprecated_group_create_custom returns the id of a newly created group ) do
    id = creator.deprecated_group_create_custom(display_name)
    assert group_exists?(id), id
    manifest = group_manifest(id)
    assert_equal display_name, manifest['display_name']
  end

  # - - - - - - - - - - - - - - - - -

  test '803',
  %w( deprecated_kata_create_custom returns the id of a newly created kata ) do
    id = creator.deprecated_kata_create_custom(display_name)
    assert kata_exists?(id), id
    manifest = kata_manifest(id)
    assert_equal display_name, manifest['display_name']
  end

end
