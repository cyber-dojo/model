# frozen_string_literal: true
require_relative 'id_generator'
require_relative 'id_pather'
require_relative 'options_checker'
require_relative 'poly_filler'
require_relative 'quoter'
require_relative '../lib/json_adapter'

# 1. Manifest now has explicit version (1)
# 2. Manifest is retrieved in single read call.
# 3. No longer stores JSON in pretty format.
# 4. No longer stores file contents in lined format.
# 5. Uses Oj as its JSON gem.
# 6. Stores explicit index in events.json summary file.
#    This improves robustness when there are Saver outages.
#    For example index==-1.
#    was    { ... } #  0
#           { ... } #  1
#    then 2-23 outage
#           { ... } # 24
#    now    { ..., "index" =>  0 }
#           { ..., "index" =>  1 }
#           { ..., "index" => 24 }
# 7. No longer uses separate dir/ for each event file.
#    This makes ran_tests() faster as it no longer needs
#    a dir_make_command() in its saver.assert_all() call.
#    was     /cyber-dojo/katas/e3/T6/K2/0/event.json
#    now     /cyber-dojo/katas/e3/T6/K2/0.event.json

class Kata_v1

  def initialize(externals)
    @externals = externals
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def exists?(id)
    unless IdGenerator::id?(id)
      return false
    end
    dir_name = kata_id_path(id)
    command = saver.dir_exists_command(dir_name)
    saver.run(command)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def create(manifest, options)
    fail_unless_known_options(options)
    manifest.merge!(options)
    manifest['version'] = 1
    manifest['created'] = time.now
    id = manifest['id'] = IdGenerator.new(@externals).kata_id
    event_summary = {
      'index' => 0,
      'time' => manifest['created'],
      'event' => 'created'
    }
    event0 = {
      'files' => manifest['visible_files']
    }
    saver.assert_all([
      manifest_file_create_command(id, json_plain(manifest)),
      events_file_create_command(id, json_plain(event_summary)),
      event_file_create_command(id, 0, json_plain(event0.merge(event_summary)))
    ])
    quoted(id)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def manifest(id)
    manifest_src = saver.assert(manifest_file_read_command(id))
    manifest = json_parse(manifest_src)
    polyfill_manifest_defaults(manifest)
    json_plain(manifest)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def events(id)
    '[' + saver.assert(events_file_read_command(id)) + ']'
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def event(id, index)
    index = index.to_i
    if index < 0
      all = json_parse(events(id))
      index = all[index]['index']
    end
    saver.assert(event_file_read_command(id, index))
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def ran_tests(id, index, files, stdout, stderr, status, summary)
    universal_append(id, index, files, stdout, stderr, status, summary)
  end

  def predicted_right(id, index, files, stdout, stderr, status, summary)
    universal_append(id, index, files, stdout, stderr, status, summary)
  end

  def predicted_wrong(id, index, files, stdout, stderr, status, summary)
    universal_append(id, index, files, stdout, stderr, status, summary)
  end

  def reverted(id, index, files, stdout, stderr, status, summary)
    universal_append(id, index, files, stdout, stderr, status, summary)
  end

  def checked_out(id, index, files, stdout, stderr, status, summary)
    universal_append(id, index, files, stdout, stderr, status, summary)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def option_get(id, name)
    fail_unless_known_option(name)
    filename = kata_id_path(id, name)
    result = saver.run(saver.file_read_command(filename))
    if result
      quoted(result.lines.last)
    else
      default = case name
      when 'theme'        then 'light'
      when 'colour'       then 'on'
      when 'predict'      then 'off'
      when 'revert_red'   then 'off'
      when 'revert_amber' then 'off'
      when 'revert_green' then 'off'
      end
      quoted(default)
    end
  end

  def option_set(id, name, value)
    fail_unless_known_option(name)
    possibles = (name === 'theme') ? ['dark','light'] : ['on', 'off']
    unless possibles.include?(value)
      fail "Cannot set theme to #{value}, only to one of #{possibles}"
    end
    filename = kata_id_path(id, name)
    result = saver.run_all([
      saver.file_create_command(filename, "\n"+value),
      saver.file_append_command(filename, "\n"+value)
    ])
    json_plain(result)
  end

  private

  include IdPather
  include JsonAdapter
  include OptionsChecker
  include PolyFiller
  include Quoter

  # - - - - - - - - - - - - - - - - - - - - - -

  def universal_append(id, index, files, stdout, stderr, status, summary)
    summary['index'] = index # See point 6 at top of file
    summary['time'] = time.now
    event_n = {
       'files' => files,
      'stdout' => stdout,
      'stderr' => stderr,
      'status' => status
    }
    result = saver.assert_all([
      # A failing create_command() ensures the append_command() is not run.
      event_file_create_command(id, index, json_plain(event_n.merge(summary))),
      events_file_append_command(id, ",\n" + json_plain(summary))
    ])
    json_plain(result)
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # manifest
  #
  # In theory the manifest could store only the display_name
  # and exercise_name and be recreated, on-demand, from the relevant
  # start-point services. In practice it creates coupling, and it
  # doesn't work anyway, since start-points change over time.

  def manifest_file_create_command(id, manifest_src)
    saver.file_create_command(manifest_filename(id), manifest_src)
  end

  def manifest_file_read_command(id)
    saver.file_read_command(manifest_filename(id))
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # events

  def events_file_create_command(id, event0_src)
    saver.file_create_command(events_filename(id), event0_src)
  end

  def events_file_append_command(id, eventN_src)
    saver.file_append_command(events_filename(id), eventN_src)
  end

  def events_file_read_command(id)
    saver.file_read_command(events_filename(id))
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # event

  def event_file_create_command(id, index, event_src)
    saver.file_create_command(event_filename(id,index), event_src)
  end

  def event_file_read_command(id, index)
    saver.file_read_command(event_filename(id,index))
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # names of dirs/files

  def manifest_filename(id)
    kata_id_path(id, 'manifest.json')
    # eg id == 'SyG9sT' ==> '/cyber-dojo/katas/Sy/G9/sT/manifest.json'
    # eg content ==> { "display_name": "Ruby, MiniTest",...}
  end

  def events_filename(id)
    kata_id_path(id, 'events.json')
    # eg id == 'SyG9sT' ==> '/cyber-dojo/katas/Sy/G9/sT/events.json'
    # eg content ==>
    # { "index": 0, ..., "event": "created" },
    # { "index": 1, ..., "colour": "red"    },
    # { "index": 2, ..., "colour": "amber"  },
  end

  def event_filename(id, index)
    kata_id_path(id, "#{index}.event.json")
    # eg id == 'SyG9sT', index == 2 ==> '/cyber-dojo/katas/Sy/G9/sT/2.event.json'
    # eg content ==>
    # {
    #   "files": {
    #     "hiker.rb": { "content": "......", "truncated": false },
    #     ...
    #   },
    #   "stdout": { "content": "...", "truncated": false },
    #   "stderr": { "content": "...", "truncated": false },
    #   "status": 1,
    #   "index": 2,
    #   "time": [ 2020,3,27,11,56,7,719235 ],
    #   "duration": 1.064011,
    #   "colour": "amber"
    # }
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def fail_unless_known_option(name)
    unless %w( theme colour predict revert_red revert_amber revert_green ).include?(name)
      fail "Unknown option #{name}"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def saver
    @externals.saver
  end

  def time
    @externals.time
  end

end
