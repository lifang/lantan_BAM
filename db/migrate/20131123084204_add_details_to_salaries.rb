class AddDetailsToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :reward_fee, :double,:default=>0
    add_column :salaries, :secure_fee, :double,:default=>0
    add_column :salaries, :voilate_fee, :double,:default=>0
  end
end
