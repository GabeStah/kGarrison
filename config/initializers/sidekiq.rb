Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'kgarrison', :url => 'redis://127.0.0.1:6379/0' }
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'kgarrison', :url => 'redis://127.0.0.1:6379/0' }
end