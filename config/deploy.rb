require 'bundler/capistrano'
require 'tmpdir'
require 'fileutils'

set :staging_server, "mimir-dev.cites.illinois.edu"
set :production_server, "mimir.cites.illinois.edu"
default_run_options[:shell] = '/bin/bash -l'

task :staging do
  role :web, staging_server
  role :app, staging_server
  role :db, staging_server, :primary => true
end

task :production do
  role :web, production_server
  role :app, production_server
  role :db, production_server, :primary => true
  before 'deploy:update_code', 'deploy:rsync_ruby'
end

set :application, "etd-reports"

set :rails_env, ENV['RAILS_ENV'] || 'production'

set :scm, :git
set :repository, 'git://github.com/hading/etd-reports.git'
set :deploy_via, :remote_cache

#directories on the server to deploy the application
#the running instance gets links to [deploy_to]/current
set :home, "/services/ideals-etd"
set :deploy_to, "#{home}/etd-reports-cap"
set :shared_config, "#{shared_path}/config"
set :public, "#{current_path}/public"

set :user, 'ideals-etd'
set :use_sudo, false

namespace :deploy do
  task :start do
#    run "cd #{home}/bin ; ./start-bibapp"
  end
  task :stop do
#    run "cd #{home}/bin ; ./stop-bibapp"
  end
  task :restart, :roles => :app, :except => {:no_release => true} do
#    ;
  end

  desc "create a config directory under shared"
  task :create_shared_dirs do
    run "mkdir #{shared_path}/config"
  end

  desc "link shared configuration"
  task :link_config do
    ['database.yml'].each do |file|
      run "ln -nfs #{shared_config}/#{file} #{current_path}/config/#{file}"
    end
  end

  #Since we can't build on the production server we have to copy the ruby and bundle gems from the test server.
  #Note that this does mean that a lot of stale gems may accumulate over time.
  #For the test server, when we move to the new servers, and assuming that we use rvm, the standard procedure should suffice to clear out
  #gems directly associated with the ruby (clear and rebuild the gemset).
  #For the shared bundle, make sure the latest code is installed and then move the capistrano shared/bundle and run
  #cap staging bundle:install. Assuming that is fine the old bundle can be removed
  #For the production server, you'll have to remove the local cache and also the target directories on the production
  #server. Then run this and everything should be copied over.
  #That said, I think by preserving the local copy, instead of having it in /tmp, should really render weeding the old
  #gems out into an optional activity. (Of course, bundler and rvm help with this as well.)

  desc "rsync the ruby directory from the test server to the production server"
  task :rsync_ruby do
    local_cache_dir = "/home/hading/cache/etd-reports"
    rsync("#{home}/.rvm/", "#{local_cache_dir}/ruby/")
    rsync("#{shared_path}/bundle/", "#{local_cache_dir}/bundle/")
#    rsync("#{home}/.passenger/", "#{local_cache_dir}/passenger/")
  end

  def rsync(remote, local)
    staqing_id = "#{user}@#{staging_server}"
    production_id = "#{user}@#{production_server}"
    system "rsync -avPe ssh #{staqing_id}:#{remote} #{local}"
    system "rsync -avPe ssh #{local} #{production_id}:#{remote}"
  end

end

after 'deploy:setup', 'deploy:create_shared_dirs'

after 'deploy:create_symlink', 'deploy:link_config'


