class CreateMatOutOrders < ActiveRecord::Migration
  #物料出库单
  def change
    create_table :mat_out_orders do |t|
      t.integer :material_id
      t.integer :staff_id
      t.number :material_num
      t.float :price
      t.integer :material_order_id

      t.datetime :created_at
    end
  end
end
