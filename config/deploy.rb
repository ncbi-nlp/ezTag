# config valid only for current version of Capistrano
lock '3.10.2'

set :application, 'eztag'
set :repo_url, 'git@github.com:ncbi-nlp/ezTag.git'

set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.3.1'

# in case you want to set ruby version from the file:
# set :rbenv_ruby, File.read('.ruby-version').strip

# set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
# set :rbenv_map_bins, %w{rake gem bundle ruby rails}
# set :rbenv_roles, :all # default value

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/tango
# set :deploy_to, '/home/deploy/bioc-viewer'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :rollbar_token, 'ce2adfd785744a63a4ba742d0bbb6a59'
set :rollbar_env, Proc.new { fetch :stage }
set :rollbar_role, Proc.new { :app }
set :passenger_restart_with_touch, true

namespace :deploy do
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
  
  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end
  namespace :assets do
    namespace :webp do

      desc 'Updates mtime for webp images'
      task :touch => [:set_rails_env] do
        on roles(:web) do
          execute <<-CMD.gsub(/[\r\n\t]?/, '').squeeze(' ').strip
          cd #{release_path.join('public/assets')};
          for asset in $(
            find . -regex ".*\.webp$" -type f | LC_COLLATE=C sort
          ); do
            echo "Update webp asset: $asset";
            touch -c -- "$asset";
          done
          CMD
        end
      end
    end
  end
end

after 'deploy:updated', 'deploy:assets:webp:touch'
