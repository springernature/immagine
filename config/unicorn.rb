APP_ROOT = File.expand_path(File.dirname(File.dirname(__FILE__)))

$LOAD_PATH.unshift File.join(APP_ROOT, 'lib')

require 'immagine'

listen            Integer(ENV['PORT'] || 5000), tcp_nopush: true
listen            ENV['SOCKET'] || '/tmp/image-server.sock'
timeout           15
preload_app       true
worker_processes  Integer(ENV['PROCESSES'] || 1)
logger            Immagine.logger

pid               ENV['PID_FILE'] if ENV['PID_FILE']
working_directory ENV['WORKING_DIR'] if ENV['WORKING_DIR']
