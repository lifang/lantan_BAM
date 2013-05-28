class AddTPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :t_price, :float
  end
end
