app_folder     = File.absolute_path(File.join(File.dirname(__FILE__), "..", ".."))
CURRENT_FOLDER = File.join(app_folder, "current")
SHARED_FOLDER  = File.join(app_folder, "shared")
LOG_FOLDER     = File.join(SHARED_FOLDER, "log")

worker_processes 10
working_directory(CURRENT_FOLDER + "/")

timeout 120

listen File.join(SHARED_FOLDER, "unicorn_image_resizer.sock"), :backlog => 64

pid File.join(SHARED_FOLDER, "pids", "unicorn.pid")

stderr_path File.join(LOG_FOLDER, "unicorn.stderr.log")
stdout_path File.join(LOG_FOLDER, "unicorn.stdout.log")
