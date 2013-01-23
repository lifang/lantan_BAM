class CreateMaterialOrders < ActiveRecord::Migration
  #物料订购
  def change
    create_table :material_orders do |t|
      t.string :code    #订单号
      t.integer :supplier_id  #供货商编号
      t.integer :supplier_type  #供货类型
      t.boolean :status      #
      t.integer :staff_id
      t.number :price
      t.datetime :arrival_at   #到达日期
      t.string :logistics_code  #物流单号
      t.string :carrier     #托运人姓名
      t.integer :store_id
      t.string :remark

      t.timestamps
    end
  end
end
