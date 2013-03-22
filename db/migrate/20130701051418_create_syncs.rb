class CreateSyncs < ActiveRecord::Migration
  def change
    create_table :syncs do |t|
      t.integer :id
      t.integer :sync_id
      t.string :table_name
      t.datetime :sync_at
    end
    add_index :syncs, :sync_at
  end
end
