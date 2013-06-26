set :use_sudo, false
set :application, "lantan_BAM"
role :web, "192.168.0.250"                          # Your HTTP server, Apache/etc
role :app, "192.168.0.250"                          # This may be the same as your `Web` server
role :db,  "192.168.0.250", :primary => true # This is where Rails migrations will run

set :scm, :git
set :repository,  "git@github.com:lifang/lantan_BAM.git"

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
default_run_options[:pty] = true
set :user, "root"
set :deploy_to, "/opt/projects/#{application}"
set :current_path, "#{deploy_to}/current"
set :shared_path, "#{deploy_to}/shared"
set :deploy_via, :remote_cache



# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

namespace :deploy do
  

  desc "Tell Passenger to restart the app."
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
    run "cd #{deploy_to}/current;rake assets:precompile"
  end

#  task :after_symlink, :roles => :app do
#
#    # database.yml for localized database connection
#    run "rm #{current_path}/config/database.yml"
#    run "ln -s #{shared_path}/database.yml #{current_path}/config/database.yml"
#
#    # log link
#    run "rm #{current_path}/log"
#    run "ln -s #{shared_path}/log/ #{current_path}/log"
#  end
end