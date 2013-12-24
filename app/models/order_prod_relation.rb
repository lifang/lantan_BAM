#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  
  def self.order_products(orders)
    products = OrderProdRelation.find_by_sql(["select opr.order_id, opr.pro_num, opr.price, opr.return_types,
   p.name,'产品/服务' p_types from order_prod_relations opr left join products p on p.id = opr.product_id
        where opr.order_id in (?)", orders])
    @product_hash = {}
    products.each { |p| 
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if products.any?
    pcar_relations = CPcardRelation.find_by_sql(["select cpr.order_id, 1 pro_num, pc.price, pc.name,return_types,
    '套餐卡' p_types from c_pcard_relations cpr inner join package_cards pc on pc.id = cpr.package_card_id where
    cpr.order_id in (?)", orders])
    pcar_relations.each { |p| 
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if pcar_relations.any?
    csvc_relations = CSvcRelation.find_by_sql(["select csr.order_id, 1 pro_num, sc.price, sc.name,return_types,
    '储值卡/打折卡' p_types from c_svc_relations csr inner join sv_cards sc on sc.id = csr.sv_card_id where csr.order_id in (?)", orders])
    csvc_relations.each { |p|
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if csvc_relations.any?
    return @product_hash
  end

  def self.s_order_products(order_id)
    products = OrderProdRelation.find_by_sql("select opr.order_id, opr.pro_num, opr.price, p.name,is_service,p.id 
        from order_prod_relations opr left join products p on p.id = opr.product_id where opr.order_id = #{order_id}")
    @product_hash = {}
    products.each { |p|
      name = p.is_service== Product::PROD_TYPES[:PRODUCT] ?  "order_prod_relation#product" :  "order_prod_relation#service"
      @product_hash[name].nil? ? @product_hash[name] = [p] : @product_hash[name] << p
    } if products.any?
    pcar_relations = CPcardRelation.find_by_sql("select cpr.order_id, 1 pro_num, pc.price, pc.name,pc.id
        from c_pcard_relations cpr inner join package_cards pc
        on pc.id = cpr.package_card_id where cpr.order_id=#{order_id}")
    pcar_relations.each { |p|
      @product_hash["c_pcard_relation#package_card"].nil? ? @product_hash["c_pcard_relation#package_card"] = [p] : @product_hash["c_pcard_relation#package_card"] << p
    } if pcar_relations.any?
    csvc_relations = CSvcRelation.find_by_sql("select csr.order_id, 1 pro_num, sc.price, sc.name,sc.id
        from c_svc_relations csr inner join sv_cards sc
        on sc.id = csr.sv_card_id where csr.order_id = #{order_id}")
    csvc_relations.each { |p|
      @product_hash["c_svc_relation#sv_card"].nil? ? @product_hash["c_svc_relation#sv_card"] = [p] : @product_hash["c_svc_relation#sv_card"] << p
    } if csvc_relations.any?

    return @product_hash
  end

  #pad上点击确认下单之后，生产一条订单记录及其与prodcuts关联的记录
  def self.make_record p_id, p_num, staff_id, cus_id, car_num_id, store_id
    Order.transaction do
      product = Product.find_by_id(p_id)
      status = 1
      msg = ""
      if product && product.is_service   #如果是服务
        check_station = Station.arrange_time(store_id, [p_id])
        case check_station[1]
        when  0
          status = 0
          msg = "当前无合适的工位!"
        when 1  #创建订单，安排工位
          pmrs = ProdMatRelation.find_by_sql(["select pmr.material_num num,pmr.material_id id,m.storage from prod_mat_relations pmr inner join materials
            m on pmr.material_id=m.id where pmr.product_id=?", product.id])
          if !pmrs.blank?
            pmrs.each do |p|
              if p.num.to_i * p_num > p.storage
                status = 0
                msg = "服务所需的物料库存不足!"
                break
              end
            end
          end
          if status==1
            order = Order.create({
                :code => MaterialOrder.material_order_code(store_id),
                :car_num_id => car_num_id,
                :status => Order::STATUS[:WAIT_PAYMENT],
                :price => product.sale_price*p_num,
                :is_billing => false,
                :front_staff_id =>staff_id,
                :customer_id => cus_id,
                :store_id => store_id,
                :is_visited => Order::IS_VISITED[:NO],
                :types => Order::TYPES[:SERVICE]
              })
            OrderProdRelation.create({
                :order_id => order.id,
                :product_id => p_id,
                :pro_num => p_num,
                :price => product.sale_price,
                :total_price => product.sale_price*p_num,
                :t_price => product.t_price*p_num
              })
            arrange_time = Station.arrange_time(store_id,[p_id],order)          
            hash = Station.create_work_order(arrange_time[0], store_id,order, {}, arrange_time[2], product.cost_time*p_num)
            order.update_attributes(hash)
            if !pmrs.blank?   #如果选择的服务是需要消耗物料的，则要将对应的物料库存减去
              pmrs.each do |p|
                material = Material.find_by_id(p.id)
                material.update_attribute("storage", material.storage - (p.num.to_i * p_num))
              end
            end
          end
        when 2
          status = 0
          msg = "需要使用多个工位，请分别下单!"
        when 3
          status = 0
          msg = "服务所需的工位没有技师!"
        end
      elsif product && !product.is_service   #如果是产品
        pmr = ProdMatRelation.find_by_product_id(product.id)
        m = Material.find_by_id(pmr.material_id) if pmr
        if m && m.storage >= p_num * pmr.material_num
          m.update_attribute("storage", m.storage - p_num * pmr.material_num)
          order = Order.create({
              :code => MaterialOrder.material_order_code(store_id),
              :car_num_id => car_num_id,
              :status => Order::STATUS[:WAIT_PAYMENT],
              :price => product.sale_price*p_num,
              :is_billing => false,
              :front_staff_id =>staff_id,
              :customer_id => cus_id,
              :store_id => store_id,
              :is_visited => Order::IS_VISITED[:NO],
              :types => Order::TYPES[:PRODUCT]
            })
          OrderProdRelation.create({
              :order_id => order.id,
              :product_id => p_id,
              :pro_num => p_num,
              :price => product.sale_price,
              :total_price => product.sale_price*p_num,
              :t_price => product.t_price*p_num
            })
        else
          status=0
          msg = "产品所需的物料库存不足!"
        end
      else
        status = 0
        msg = "数据错误!"
      end
      return [status, msg, product, order]
    end
  end

end
