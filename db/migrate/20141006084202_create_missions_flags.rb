class CreateMissionsFlags < ActiveRecord::Migration
  def change
    create_table :flags_missions, id: false do |t|
      t.belongs_to :flag
      t.belongs_to :mission
    end
    add_index :flags_missions, [:flag_id, :mission_id], unique: true, name: 'by_flag_and_mission'
  end
end
