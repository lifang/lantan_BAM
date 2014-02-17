class AddWarnTimeToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :warn_time, :datetime
  end
end
