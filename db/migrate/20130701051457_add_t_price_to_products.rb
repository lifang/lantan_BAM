class AddTPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :t_price, :float  #成本价
  end
end
