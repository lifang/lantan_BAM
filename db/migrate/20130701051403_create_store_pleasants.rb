class CreateStorePleasants < ActiveRecord::Migration
  def change
    create_table :store_pleasants do |t|
      t.integer :id
      t.string :store_id
      t.string :img_url
      t.datetime :created_at
    end
    add_index :store_pleasants, :store_id
    add_index :store_pleasants, :created_at
  end
end
