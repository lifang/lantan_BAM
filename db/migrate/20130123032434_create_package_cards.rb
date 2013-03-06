class CreatePackageCards < ActiveRecord::Migration
  #套餐卡
  def change
    create_table :package_cards do |t|
      t.string :name
      t.string :img_url
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :store_id
      t.boolean :status
      t.integer :price

      t.datetime :created_at
    end

    add_index :package_cards, :store_id
    add_index :package_cards, :status
    add_index :package_cards, :created_at
  end
end
