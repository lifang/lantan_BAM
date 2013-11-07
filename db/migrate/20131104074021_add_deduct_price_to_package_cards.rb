class AddDeductPriceToPackageCards < ActiveRecord::Migration
  def change
    add_column :package_cards, :deduct_price, :float,:default=>0
    add_column :package_cards, :deduct_percent, :float,:default=>0
    add_column :orders,:front_deduct,:float,:default=>0
    add_column :orders,:technician_deduct,:float,:default=>0
  end
end
