class CreateMissionsAbilities < ActiveRecord::Migration
  def change
    create_table :abilities_missions, id: false do |t|
      t.belongs_to :ability
      t.belongs_to :mission
    end
    add_index :abilities_missions, [:ability_id, :mission_id], unique: true, name: 'by_ability_and_mission'
  end
end
