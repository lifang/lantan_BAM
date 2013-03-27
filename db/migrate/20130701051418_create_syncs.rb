class CreateSyncs < ActiveRecord::Migration
  def change
    create_table :syncs do |t|
      t.integer :id
      t.integer :store_id
      t.datetime :sync_at
    end
    add_index :syncs, :sync_at
  end
end
