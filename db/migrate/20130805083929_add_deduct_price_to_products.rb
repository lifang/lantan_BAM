class AddDeductPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :deduct_price, :float
  end
end
