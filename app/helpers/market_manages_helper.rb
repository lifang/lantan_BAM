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

  def prod_gross_price(order_id, oprr)
    total_price = oprr.total_price.to_f  #每项商品总价
    opcr = OPcardRelation.where(:order_id => order_id, :product_id => oprr.product_id).first
    unless opcr.blank?
      deals_price = (opcr.product_num * oprr.price).to_f #每项商品使用套餐卡抵付的价格
      prod_full_price_num = oprr.pro_num - opcr.product_num #未使用套餐卡抵付的商品数目
      prod_cost_price = prod_full_price_num *(oprr.t_price.to_f) #未使用套餐卡抵付的商品成本价
    end
    # 使用活动优惠总价
    opt_sale = OrderPayType.where(:order_id => order_id, :product_id => oprr.product_id, :pay_type => OrderPayType::PAY_TYPES[:SALE]).first
    unless opt_sale.blank?
      sale_price = opt_sale.price
    end

    # 使用打折卡优惠总价
    opt_sav = OrderPayType.where(:order_id => order_id, :product_id => oprr.product_id, :pay_type => OrderPayType::PAY_TYPES[:SV_CARD]).first
    unless opt_sav.blank?
      sav_price = opt_sav.price
    end

    ssale_price = total_price - deals_price.to_f - sale_price.to_f - sav_price.to_f  #零售价

    gross_profit = ssale_price - prod_cost_price.to_f #一个商品的毛利

    return [prod_cost_price, ssale_price,gross_profit]
  end
end
