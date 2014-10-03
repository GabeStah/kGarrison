set :application, 'kgarrison'
set :repository,  'https://github.com/GabeStah/kGarrison.git'

# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, 'http://107.170.230.211'
role :app, 'http://107.170.230.211'                          # This may be the same as your `Web` server
role :db,  'http://107.170.230.211', :primary => true # This is where Rails migrations will run

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