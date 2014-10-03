require "bundler/capistrano"

# enable multistage
require 'capistrano/ext/multistage'

# define our stages, remember that if it isn't defined here
# it won't be picked up.
set :stages, %w(production)
set :default_stage, "production"

# simple method to create a file from an erb template. Used
# to generate dynamic configuration files.
def template(from, to)
  erb = File.read(from)
  put ERB.new(erb).result(binding), to
end