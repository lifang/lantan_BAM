class AddIsAddedToProducts < ActiveRecord::Migration
  def change
    add_column :products, :is_added, :boolean,:default=>0
  end
end
