require "bundler/capistrano"

# enable multistage
require 'capistrano/ext/multistage'
require 'capistrano/sidekiq'

# define our stages, remember that if it isn't defined here
# it won't be picked up.
set :stages, %w(production)
set :default_stage, "production"

set :sidekiq_cmd, "#{fetch(:bundle_cmd, "bundle")} exec sidekiq"  # Only for capistrano2.5
set :sidekiqctl_cmd, "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" # Only for capistrano2.5

# simple method to create a file from an erb template. Used
# to generate dynamic configuration files.
def template(from, to)
  erb = File.read(from)
  put ERB.new(erb).result(binding), to
end