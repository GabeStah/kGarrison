class UpdateMissionsWorker
  include Sidekiq::Worker

  def perform
    Parse.update_all("http://#{Settings.subdomain}.wowdb.com/garrison/missions")
  end
end