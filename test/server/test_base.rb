# frozen_string_literal: true
require_relative 'capture_stdout_stderr'
require_relative 'external_custom_start_points'
require_relative '../id58_test_base'
require_source 'app'
require_source 'externals'
require 'json'

class TestBase < Id58TestBase

  include CaptureStdoutStderr
  include Rack::Test::Methods # [1]

  def app # [1]
    App.new(externals)
  end

  def model
    Model.new(externals)
  end

  def custom_start_points
    ExternalCustomStartPoints.new
  end

  def saver
    externals.saver
  end

  def externals
    @externals ||= Externals.new
  end

  # - - - - - - - - - - - - - - -

  def assert_get_200(path, &block)
    stdout,stderr = capture_stdout_stderr {
      get '/'+path
    }
    assert_status 200
    assert_equal '', stderr, :stderr
    assert_equal '', stdout, :sdout
    block.call(json_response_body)
  end

  def assert_json_post_200(path, args, &block)
    stdout,stderr = capture_stdout_stderr {
      json_post '/'+path, args
    }
    assert_status 200
    assert_equal '', stderr, :stderr
    assert_equal '', stdout, :stdout
    block.call(json_response_body)
  end

  def json_post(path, data)
    post path, data.to_json, JSON_REQUEST_HEADERS
  end

  JSON_REQUEST_HEADERS = {
    'CONTENT_TYPE' => 'application/json', # sending
    'HTTP_ACCEPT' => 'application/json'   # receive
  }

  def json_response_body
    assert_equal 'application/json', last_response.headers['Content-Type']
    JSON.parse(last_response.body)
  end

  # - - - - - - - - - - - - - - -

  def assert_get_500(path, &block)
    stdout,stderr = capture_stdout_stderr { get '/'+path }
    assert_status 500
    assert_equal '', stderr, :stderr
    assert_equal stdout, last_response.body+"\n", :stdout
    block.call(json_response_body)
  end

  # - - - - - - - - - - - - - - -

  def assert_status(expected)
    assert_equal expected, last_response.status, :last_response_status
  end

  # - - - - - - - - - - - - - - -

  def assert_group_exists(id, display_name, exercise_name=nil)
    refute_nil id, :id
    assert group_exists?(id), "!group_exists?(#{id})"
    manifest = group_manifest(id)
    assert_equal display_name, manifest['display_name'], manifest.keys.sort
    if exercise_name.nil?
      refute manifest.has_key?('exercise'), :exercise
    else
      assert_equal exercise_name, manifest['exercise'], :exercise
    end
  end

  def group_exists?(id)
    model.group_exists?(id:id)
  end

  def group_manifest(id)
    model.group_manifest(id:id)
  end

  # - - - - - - - - - - - - - - -

  def assert_kata_exists(id, display_name, exercise_name=nil)
    refute_nil id, :id
    assert kata_exists?(id), "!kata_exists?(#{id})"
    manifest = kata_manifest(id)
    assert_equal display_name, manifest['display_name'], manifest.keys.sort
    if exercise_name.nil?
      refute manifest.has_key?('exercise'), :exercise
    else
      assert_equal exercise_name, manifest['exercise'], :exercise
    end
  end

  def kata_exists?(id)
    model.kata_exists?(id:id)
  end

  def kata_manifest(id)
    model.kata_manifest(id:id)
  end

end
