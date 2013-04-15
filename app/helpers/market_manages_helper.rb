module MarketManagesHelper
  def get_service_products(order)
    Product.find_by_sql("select p.name, p.id, op.price price,op.pro_num pro_num from products p inner join
                        order_prod_relations op on op.product_id = p.id inner join orders o on o.id=op.order_id
                        where o.id=#{order.id}")
    #p.is_service=#{Product::PROD_TYPES[:SERVICE]} 
  end

end
