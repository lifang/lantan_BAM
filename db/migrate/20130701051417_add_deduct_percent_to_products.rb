class AddDeductPercentToProducts < ActiveRecord::Migration
  def change
    add_column :products, :deduct_percent, :float
  end
end
