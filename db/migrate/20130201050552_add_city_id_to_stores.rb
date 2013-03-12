class AddCityIdToStores < ActiveRecord::Migration
  def change
    add_column :stores, :city_id, :integer
    
    add_index :stores, :city_id
  end
end
