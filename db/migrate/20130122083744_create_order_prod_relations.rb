class CreateOrderProdRelations < ActiveRecord::Migration
  #产品订单表
  def change
    create_table :order_prod_relations do |t|
      t.integer :order_id
      t.integer :product_id
      t.integer :pro_num   #产品数量
      t.float :price   #价格

    end

    add_index :order_prod_relations, :order_id
    add_index :order_prod_relations, :product_id
  end
end
