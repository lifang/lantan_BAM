class CreateJvSyncs < ActiveRecord::Migration
  def change
    create_table :jv_syncs do |t|
      t.integer :types
      t.datetime :current_day
      t.integer :hours
      t.string :zip_name
      t.integer :target_id
    end
    add_index :jv_syncs, :current_day
  end
end
