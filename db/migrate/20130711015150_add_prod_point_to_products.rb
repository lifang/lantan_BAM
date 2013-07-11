class AddProdPointToProducts < ActiveRecord::Migration
  def change
    add_column :products, :prod_point, :integer
  end
end
