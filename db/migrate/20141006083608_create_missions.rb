class CreateMissions < ActiveRecord::Migration
  def change
    create_table :missions do |t|
      t.integer :cooldown
      t.integer :cost
      t.integer :duration
      t.integer :followers
      t.integer :item_level
      t.integer :level
      t.string :location
      t.string :mechanic
      t.string :name
      t.integer :reward

      t.timestamps
    end
  end
end
