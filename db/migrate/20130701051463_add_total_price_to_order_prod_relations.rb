class AddTotalPriceToOrderProdRelations < ActiveRecord::Migration
  def change
    add_column :order_prod_relations, :total_price, :float #订单每项商品的总价
    add_column :order_prod_relations, :t_price, :float #订单每项商品的成本价
    add_column :order_pay_types, :product_id, :integer #订单付款是为哪一项付款
  end
end
