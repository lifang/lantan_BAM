set :use_sudo, false
set :group_writable, false
set :keep_releases, 2 # Less releases, less space wasted
set :runner, nil # thanks to http://www.rubyrobot.org/article/deploying-rails-20-to-mongrel-with-capistrano-21
set :application, "lantan_BAM"

default_run_options[:pty] = true
set :scm, :git
set :repository,  "git@github.com:lifang/lantan_BAM.git"
set :ssh_options, { :forward_agent => true }
set :git_shallow_clone, 1
set :short_branch, "master"

#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
require "bundler/capistrano"
set :rvm_type, :system

set :default_stage, "staging"
set :stages, %w(staging production)
set :rvm_ruby_string, '1.9.2-p320@rails3.1.2'

require 'capistrano/ext/multistage'
require 'capistrano_colors'

on :start do
  `ssh-add`
end

after("deploy:symlink") do
    # database.yml for localized database connection
    run "rm #{current_path}/config/database.yml"
    run "ln -s #{shared_path}/database.yml #{current_path}/config/database.yml"

    # log link
    run "rm #{current_path}/log"
    run "ln -s #{shared_path}/log/ #{current_path}/log"
end

namespace :deploy do  
  task :restart do
    run "chmod -R 777 /opt/projects/lantan_BAM/"
#    run "/etc/init.d/nginx restart"
    run "touch #{current_path}/tmp/restart.txt"
#    run "rm -rf #{current_path}/tmp/"
  end
end