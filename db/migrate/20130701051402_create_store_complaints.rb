class CreateStoreComplaints < ActiveRecord::Migration
  def change
    create_table :store_complaints do |t|
      t.integer :id
      t.string :store_id
      t.string :img_url
       t.datetime :created_at
    end
     add_index :store_complaints, :store_id
     add_index :store_complaints, :created_at
  end
end
