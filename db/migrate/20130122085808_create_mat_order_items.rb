class CreateMatOrderItems < ActiveRecord::Migration
  #物料订单条目表
  def change
    create_table :mat_order_items do |t|
      t.integer :material_order_id
      t.integer :material_id
      t.number :material_num
      t.number :price

      t.timestamps
    end
  end
end
