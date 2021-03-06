# frozen_string_literal: true
require_relative '../id58_test_base'
require_relative 'capture_stdout_stderr'
require_relative 'external_custom_start_points'
require_source 'externals'
require_source 'model'
require_source 'prober'

class TestBase < Id58TestBase

  include CaptureStdoutStderr

  def externals
    @externals ||= Externals.new
  end

  def prober
    Prober.new(externals)
  end

  def model
    Model.new(externals)
  end

  def custom_start_points
    ExternalCustomStartPoints.new
  end

  # - - - - - - - - - - - - -

  def default_options
    {}
  end

  # - - - - - - - - - - - - -

  def true?(b)
    b.is_a?(TrueClass)
  end

  def false?(b)
    b.is_a?(FalseClass)
  end

end
