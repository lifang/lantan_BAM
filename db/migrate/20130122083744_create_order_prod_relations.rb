class CreateOrderProdRelations < ActiveRecord::Migration
  #产品订单表
  def change
    create_table :order_prod_relations do |t|
      t.integer :order_id
      t.integer :product_id
      t.number :pro_num   #产品数量
      t.integer :price   #价格

      t.timestamps
    end
  end
end
