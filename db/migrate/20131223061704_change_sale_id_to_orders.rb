class ChangeSaleIdToOrders < ActiveRecord::Migration
 def change
    change_column :orders, :sale_id, :integer
 end
end
