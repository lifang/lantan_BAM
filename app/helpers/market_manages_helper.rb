module MarketManagesHelper
  def get_service_products(order)
    Product.includes(:order_prod_relations => :order).
      where("orders.id = #{order.id}").where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").
      select("products.name, products.id")
  end

  def get_order_prod_relation(order_id, product_id)
    OrderProdRelation.where("order_id = #{order_id} and product_id = #{product_id}").first
  end

  def get_products_name(order)
    products = Product.includes(:order_prod_relations => :order).
      where("orders.id = #{order.id}").where("products.is_service = #{Product::PROD_TYPES[:SERVICE]}").
      select("products.name")
    products.collect{|prod| prod.name}
  end

  def get_svc_return_record(order_id, store_id)
    SvcReturnRecord.where("types = #{SvcReturnRecord::TYPES[:IN]} and target_id = #{order_id} and store_id = #{store_id}").first
  end
end
