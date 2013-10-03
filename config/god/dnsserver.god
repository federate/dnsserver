base_path = ENV['DNS_SERVER_ROOT'] || File.expand_path("../../../", __FILE__)

config_dir    = File.join(base_path, 'config')
log_dir       = File.join(base_path, 'logs')
pid_dir       = File.join(base_path, 'tmp/pids')
bin_dir       = File.join(base_path, 'bin')

server_pid_file = File.join(pid_dir, "dnsserver.pid")
server_executable_path = File.join(bin_dir, 'dnsserver')
server_config_file = File.join(config_dir, 'server.yml')
log_file = File.join(log_dir, 'server.log')

ruby_gc_settings = ENV['RUBY_GC_SETTINGS'] || {
  'RUBY_GC_MALLOC_LIMIT' => 100000000,
  'RUBY_HEAP_MIN_SLOTS' => 2000000,
  'RUBY_HEAP_SLOTS_INCREMENT' => 200000,
  'RUBY_HEAP_SLOTS_GROWTH_FACTOR' => 1,
  'RUBY_HEAP_FREE_MIN' => 20000
}

God.watch do |w|
  w.env             = ruby_gc_settings
  w.dir             = base_path
  w.group           = "misc"
  w.name            = "dnsserver"
  w.interval        = 20.seconds
  w.start           = "#{server_executable_path} -d -c #{server_config_file} -P #{server_pid_file} -l #{log_file}"
  w.stop            = "#{server_executable_path} -k -c #{server_config_file} -P #{server_pid_file} -l #{log_file}"
  w.start_grace     = 15.seconds
  w.restart_grace   = 15.seconds
  w.pid_file        = server_pid_file
  w.log             = log_file
  w.err_log         = log_file
  w.log_cmd         = '/usr/bin/logger'

  if Process.uid == 0
    w.uid = 'apache'
    w.gid = 'apache'
  end

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 10.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 10.seconds
    end

    if Process.uid == 0
      on.condition(:process_exits) do |c|
        c.notify = {:contacts => ['operations', 'developers'], :priority => 1, :category => 'dnsserver'}
      end
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
      c.interval = 20.seconds
    end
  end
end
