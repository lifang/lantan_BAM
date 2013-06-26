set :use_sudo, false
set :application, "lantan_BAM"
default_run_options[:pty] = true
set :scm, :git
set :ssh_options, { :forward_agent => true } 
set :repository,  "git@github.com:lifang/lantan_BAM.git"

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :user, "root"
set :deploy_to, "/opt/projects/#{application}"
set :current_path, "#{deploy_to}/current"
set :shared_path, "#{deploy_to}/shared"

role :web, "192.168.0.250"                          # Your HTTP server, Apache/etc
role :app, "192.168.0.250"                          # This may be the same as your `Web` server
role :db,  "192.168.0.250", :primary => true # This is where Rails migrations will run
set :rails_env, 'production'

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
    run "cd #{deploy_to}/current;rake assets:precompile"
  end
end