set :user, "root"
set :deploy_to, "/var/www/lantan_BAM"
set :current_path, "#{deploy_to}/current"
set :shared_path, "#{deploy_to}/shared"
role :web, "192.168.0.250"                          # Your HTTP server, Apache/etc
role :app, "192.168.0.250"                          # This may be the same as your `Web` server
role :db,  "192.168.0.250", :primary => true # This is where Rails migrations will run
set :rails_env, 'production'

