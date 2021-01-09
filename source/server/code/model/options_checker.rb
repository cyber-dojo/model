# frozen_string_literal: true

module OptionsChecker

  def fail_unless_known_options(options)
    unless options.is_a?(Hash)
      fail "options is not a Hash"
    end
    options.each do |key,value|
      unless known_option_key?(key)
        fail "options:{#{quoted(key)}: #{value}} unknown key: #{quoted(key)}"
      end
      unless known_option_value?(key, value)
        fail "options:{#{quoted(key)}: #{value}} unknown value: #{value}"
      end
    end
  end

  def known_option_key?(key)
    key.is_a?(String) && ["fork_button","theme","colour","predict"].include?(key)
  end

  def known_option_value?(key, value)
    case key
    when "colour"      then return ["on","off"].include?(value)
    when "fork_button" then return ["on","off"].include?(value)
    when "predict"     then return ["on","off"].include?(value)
    when "theme"       then return ["dark","light"].include?(value)
    end
    false
  end

end
