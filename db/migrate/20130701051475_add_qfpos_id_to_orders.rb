class AddQfposIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :qfpos_id, :string
  end
end
