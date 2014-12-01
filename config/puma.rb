APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

$LOAD_PATH.unshift File.join(APP_ROOT, 'lib')

require 'image_resizer'

port   = Integer(ENV['PORT'] || 5000)
socket = ENV['SOCKET'] || '/tmp/image-server.sock'

environment       ENV['RACK_ENV']
daemonize         false
worker_timeout    15

pidfile           ENV['PID_FILE'] if ENV['PID_FILE']
state_path        ENV['STATE_FILE'] if ENV['STATE_FILE']

# TODO Figure out a way to log to syslog

preload_app!
threads           0, 16
workers           Integer(ENV['PROCESSES'] || 2)

bind              "tcp://0.0.0.0:#{port}"
bind              "unix://#{socket}"

tag               'image_resizer'
