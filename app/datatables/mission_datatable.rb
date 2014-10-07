class MissionDatatable < AjaxDatatablesRails::Base
  include AjaxDatatablesRails::Extensions::WillPaginate

  def_delegators :@view, :l, :link_to

  def sortable_columns
    @sortable_columns ||= [
      'missions.name',
      'missions.cooldown',
      'missions.cost',
      'missions.duration',
      'missions.followers',
      'missions.item_level',
      'missions.level',
      'missions.location',
      'missions.mechanic',
      'missions.reward',
      'abilities.name',
      'flags.name'
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      'missions.name',
      'missions.cooldown',
      'missions.cost',
      'missions.duration',
      'missions.followers',
      'missions.item_level',
      'missions.level',
      'missions.location',
      'missions.mechanic',
      'missions.reward',
      'abilities.name',
      'flags.name'
    ]
  end

  private

  def data
    records.map do |mission|
      [
        link_to(mission.name, mission.url),
        mission.cooldown,
        mission.cost ? mission.cost : nil,
        mission.duration,
        mission.followers,
        mission.item_level,
        mission.level,
        mission.location,
        mission.mechanic,
        mission.reward,
        mission.abilities.map(&:name),
        mission.flags.map(&:name)
      ]
    end
  end

  def get_raw_records
    Mission.all.eager_load(:abilities, :flags)
  end
end
