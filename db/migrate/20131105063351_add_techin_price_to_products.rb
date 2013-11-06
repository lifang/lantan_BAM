class AddTechinPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :techin_price, :float,:default=>0
    add_column :products, :techin_percent, :float,:default=>0
  end
end
