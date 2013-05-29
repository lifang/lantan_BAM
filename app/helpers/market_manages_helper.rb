module MarketManagesHelper
  def get_service_products(order)
    products = Product.find_by_sql("select p.name name, p.id, op.price price,op.pro_num pro_num from products p inner join
                        order_prod_relations op on op.product_id = p.id inner join orders o on o.id=op.order_id
                        where o.id=#{order.id}")
    pcar_relations = CPcardRelation.find_by_sql("select pc.price price, pc.name name, 1 pro_num 
        from c_pcard_relations cpr inner join package_cards pc
        on pc.id = cpr.package_card_id where cpr.order_id = #{order.id}")
    products + pcar_relations
    #p.is_service=#{Product::PROD_TYPES[:SERVICE]} 
  end

end
