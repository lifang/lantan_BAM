module MarketManagesHelper
  def get_service_products(order)
    Product.find_by_sql("select p.name, p.id, op.price price,op.pro_num pro_num from products p inner join
                        order_prod_relations op on op.product_id = p.id inner join orders o on o.id=op.order_id
                        where p.is_service=#{Product::PROD_TYPES[:SERVICE]} and o.id=#{order.id}")
  end

#  def get_order_prod_relation(order_id, product_id)
#    OrderProdRelation.where("order_id = #{order_id} and product_id = #{product_id}").first
#  end

#  def get_products_name(order)
#    products = Product.includes(:order_prod_relations => :order).
#      where("orders.id = #{order.id}").where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").
#      select("products.name")
#    products.collect{|prod| prod.name}
#  end

  def get_svc_return_record(order_id, store_id)
    SvcReturnRecord.where("types = #{SvcReturnRecord::TYPES[:IN]} and target_id = #{order_id} and store_id = #{store_id}").first
  end
end
