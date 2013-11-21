class ChangeDeductPriceToProducts < ActiveRecord::Migration
  def change
    change_column :products,:deduct_price,:float,:default=>0
    change_column :products,:deduct_percent,:float,:default=>0
  end
end
