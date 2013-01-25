class CreateMatInOrders < ActiveRecord::Migration
  #物料入库表
  def change
    create_table :mat_in_orders do |t|
      t.integer :material_order_id
      t.integer :material_id
      t.number :material_num
      t.float :price
      t.integer :staff_id

      t.datetime :created_at
    end
  end
end
