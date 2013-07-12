class AddAutoTimeToOrders < ActiveRecord::Migration
  def change
     add_column :orders, :auto_time, :datetime
  end
end
