#encoding: utf-8
require 'json'
require "uri"
class Api::NewAppOrdersController < ApplicationController

  #登录后返回数据
  def new_index_list
    #参数store_id
    status = 0
    #orders => 车位施工情况
    #    begin
    #订单分组
    work_orders = working_orders params[:store_id]
    #stations_count => 工位数目
    station_ids = Station.where("store_id =? and status not in (?) ",params[:store_id], [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
    services = Product.is_service.is_normal.commonly_used.where(:store_id => params[:store_id]).select("id, name, sale_price as price")
    #    rescue
    #      status = 1
    #    end

    render :json => {:status => status, :orders => work_orders, :station_ids => station_ids, :services => services}
  end

  #生成订单
  #  Started POST "/api/new_app_orders/make_order" for 192.168.0.104 at 2013-10-15 19:53:26 +0800
  #  Processing by Api::NewAppOrdersController#make_order as */*
  #  Parameters: {"is_car_num"=>"1", "num"=>"鑻廞12345", "service_id"=>"12", "store_id"=>"1", "user_id"
  #=>"3"}
  def make_order
    #参数num(car_num||phone), is_car_num(标志是否是车牌号)，service_id, store_id, user_id
    hash = {}
    status = 1
    car_num = nil
    customer = nil
    phone_flag = false
    if params[:is_car_num]=="1"
      customer = CarNum.get_customer_info_by_carnum(params[:store_id], params[:num])
    else
      customers = Customer.find_by_sql(["select distinct cu.id customer_id, cu.name name, cn.num car_num from customers cu
        inner join customer_num_relations cnr on cu.id=cnr.customer_id inner join customer_store_relations csr on csr.customer_id = cu.id
        inner join car_nums cn on cn.id=cnr.car_num_id where csr.store_id in (?) and cu.mobilephone = ? and cu.status= ? ",
          StoreChainsRelation.return_chain_stores(params[:store_id]), params[:num].strip,Customer::STATUS[:NOMAL] ])
      customer = customers[0]
      if customers.length == 1
        phone_flag = true
      end
      status = customers.length > 1 ? 5 : 1
    end

    if status == 5 #多个车牌
      render :json => {:status => status, :car_nums => customers.map(&:car_num)}
    else
      if customer.blank?
        Customer.transaction do
          customer = Customer.create({:name => params[:num], :mobilephone => params[:num]})
          car_num = CarNum.create(:num => params[:num])
          customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
          relation = CustomerStoreRelation.find_by_store_id_and_customer_id(params[:store_id], customer.id)
          customer.customer_store_relations.create({:customer_id => customer.id, :store_id => params[:store_id]}) unless relation
          customer.save
        end
      else
        if phone_flag
          car_num = CarNum.find_by_sql("select cn.id from car_nums cn inner join customer_num_relations cnr on cnr.car_num_id=cn.id where cnr.customer_id = #{customer.customer_id}")[0]
        else
          car_num = CarNum.find_by_num(params[:num])
        end
      end
      Order.transaction do
        service = Product.find_by_id_and_status(params[:service_id], Product::IS_VALIDATE[:YES])
        
        order = Order.create({
            :code => MaterialOrder.material_order_code(params[:store_id].to_i),
            :car_num_id => car_num.try(:id),
            :status => Order::STATUS[:NORMAL],
            :price => service.try(:sale_price),
            :is_billing => false,
            :front_staff_id => params[:user_id],
            :customer_id => customer.id || customer.customer_id,
            :store_id => params[:store_id],
            :is_visited => Order::IS_VISITED[:NO],
            :types => Order::TYPES[:SERVICE]
          })
        
        status = Product.return_station_status([service.id], params[:store_id], nil, order)[0] # 1 有符合工位 2 没工位 3 多个工位 4 工位上暂无技师

        if status != 1
          order.destroy
        else
          station_id = Product.return_station_status([service.id], params[:store_id], nil, order)[2]

          work_order_status = Product.return_station_status([service.id], params[:store_id], nil, order)[3]
          hash = Station.create_work_order(station_id, params[:store_id],order, hash, work_order_status,service.cost_time.to_i)
          if order.update_attributes hash
            status = 1
            OrderProdRelation.create(:order_id => order.id, :product_id => service.id,
              :pro_num => 1, :price => service.sale_price, :t_price => service.t_price, :total_price => service.sale_price.to_f)
          end
        end

        #再次返回orders
        work_orders = working_orders params[:store_id]
        render :json => {:status => status, :orders => work_orders}
      end
    end
    
  end

  #根据实际情况调换工位
  def change_station
    #参数 "(work_order_id)_(station_id),(work_order_id)_(station_id)", store_id
    status = 0
    if params[:wo_station_ids]
      WorkOrder.transaction do
        wo_station_ids = params[:wo_station_ids].split(",")
        wo_station_ids.each do |wo_station|
          wo_id,station_id = wo_station.split("_")
          wo = WorkOrder.find_by_id(wo_id)
          status = wo && wo.update_attribute(:station_id, station_id.to_i) ? 0 : 1
        end
      end
      work_orders = working_orders params[:store_id]
    else
      status = 1  
    end
    render :json => {:status => status, :orders => work_orders}
  end

  #施工完成 -> 等待付款
  def work_order_finished
    #work_order_id
    work_order = WorkOrder.find_by_id(params[:work_order_id])
    
    if work_order
      if work_order.status==WorkOrder::STAT[:WAIT_PAY]
        status = 0
        #"此车等待付款"
      else
        status = 1
        # "操作成功"
        work_order.arrange_station
      end
    else
      #"工单未找到"
      status = 2
    end
    work_orders = working_orders params[:store_id]
    render :json => {:status => status, :orders => work_orders}
  end

  #准备order相关内容付款
  def order_info
    #order_id
    status = 0
    order = Order.find_by_id(params[:order_id])
    if order.status == Order::STATUS[:BEEN_PAYMENT]
      status = 1 #已经付过款
      work_orders = working_orders params[:store_id]
      render :json => {:status => status, :orders => work_orders}
    else
      p_cards = []
      product = Product.find_by_sql(["select p.* from products p inner join order_prod_relations opr on opr.product_id = p.id
inner join orders o on o.id = opr.order_id where p.status = ? and p.is_service = ? and o.id = ?",Product::IS_VALIDATE[:YES], Product::PROD_TYPES[:SERVICE], order.id])[0]
      #产品相关活动
      sale_hash, prod_arr = Order.get_sale_by_product(product, nil, 0, {}, [])[0..1] if product
      sale_arr = sale_hash.values if sale_hash
      #客户相关打折卡
      customer = Customer.find_by_id(order.customer_id)
      discount_card_arr = customer.get_discount_cards([]) if customer
      #客户相关套餐卡
      customer_pcards = CPcardRelation.find_by_sql("select cpr.* from c_pcard_relations cpr
        inner join pcard_prod_relations ppr on ppr.package_card_id = cpr.package_card_id
        where cpr.status = #{CPcardRelation::STATUS[:NORMAL]} and cpr.ended_at >= '#{Time.now()}'
      and product_id = #{product.id} and cpr.customer_id = #{customer.id} group by cpr.id")
    
      customer_pcards.each do |c_pr|
        p_c = c_pr.package_card
        p_c[:products] = p_c.pcard_prod_relations.collect{|r|
          p = Hash.new
          p[:name] = r.product.name
          prod_num = c_pr.get_prod_num r.product_id
          p[:num] =  prod_num.to_i
          p[:p_card_id] = r.package_card_id
          p[:product_id] = r.product_id
          p[:product_price] = r.product.sale_price
          p[:selected] = 1
          p
        }
        p_c[:cpard_relation_id] = c_pr.id
        p_c[:has_p_card] = 1
        p_c[:show_price] = 0.0
        p_cards << p_c
      end if customer_pcards.any?

      result = {:status => status, :info => {:order_id => order.id, :order_code => order.code}, :products => prod_arr, :sales => sale_arr,
        :svcards => discount_card_arr, :pcards => p_cards, :total => order.price, :content  => "成功", :car_num => order.car_num.try(:num)}
      render :json => result.to_json
    end
  end

  #付款
  def pay_order
    #产品：0， 活动：1， 打折卡：2， 套餐卡：3
    #参数保存，更新order使用优惠相关 :prods => "0_pid,1_saleid_优惠价格,2_svcardid_优惠价格,3_pcard_id"，order_code,price, store_id
    #参数：付款相关 params[:please], params[:pay_type], params[:billing], params[:code], params[:is_free], params[:appid]
    Order.transaction do
      hash = {}
      hash[:price] = params[:price].to_f
      order = Order.find_by_id(params[:order_id]) if params[:order_id]

      #保存order使用的相关优惠
      prod_arr = params[:prods].split(",") if params[:prods]
      prod_ids,sale_ids,discount_card_ids,cp_relation_ids = [],nil,nil,[]
      prod_arr.each do |p|
        a = p.split("_")
        case a[0].to_i
        when 0
          prod_ids << a[1].to_i
        when 1
          sale_ids = {:id =>a[1].to_i,:price => a[2].to_f}
        when 2
          discount_card_ids = {:id => a[1].to_i, :price => a[2].to_f}
        when 3
          cp_relation_ids << a[1].to_i
        end
      end
      product = Product.find_by_id(prod_ids[0])
      if product.present?
        #活动优惠
        if sale_ids.present? && Sale.find_by_id_and_store_id_and_status(sale_ids[:id],params[:store_id],Sale::STATUS[:RELEASE])
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE],
            :product_id => product.id, :price => sale_ids[:price], :product_num => 1)
          hash[:sale_id] = sale_ids[:id]
        end

        #打折卡优惠
        if discount_card_ids.present? && SvCard.find_by_id_and_store_id_and_status(discount_card_ids[:id],params[:store_id], SvCard::STATUS[:NORMAL])
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
            :product_id => product.id, :price => discount_card_ids[:price], :product_num => 1)
        end

        #储值卡优惠
        if cp_relation_ids.present?
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
            :product_id => product.id, :price => product.sale_price, :product_num => 1)
          #customer = Customer.find_by_id order.customer_id
          c_pcard_relations = CPcardRelation.find_by_id(cp_relation_ids[0])
          cpr_content = c_pcard_relations.content.split(",") if c_pcard_relations
          content = []
          (cpr_content ||[]).each do |pnn|
            prod_name_num = pnn.split("-")
            prod_id = prod_name_num[0].to_i
            if prod_id == product.id
              content << "#{prod_id}-#{prod_name_num[1]}-#{prod_name_num[2].to_i - 1}"
            else
              content << pnn
            end
          end
          unless content.blank?
            c_pcard_relations.update_attribute(:content, content.join(","))
            OPcardRelation.create({:order_id => order.id, :c_pcard_relation_id => c_pcard_relations.id,
                :product_id =>product.id, :product_num => 1}) if c_pcard_relations
          end
        end
      end
      order.update_attributes hash

      #实际付款
      order_pay = Order.pay(order.id, params[:store_id], params[:please],
        params[:pay_type], params[:billing], params[:code], params[:is_free], params[:appid])
      content = ""
      if order_pay[0] == 0
        content = ""
      elsif order_pay[0] == 1
        content = "success"
      elsif order_pay[0] == 2
        content = "订单不存在"
      elsif order_pay[0] == 3
        content = "储值卡余额不足，请选择其他支付方式"
      end
      work_orders = working_orders params[:store_id]

      render :json => {:status => order_pay[0], :content => content, :orders => work_orders}
    end
  end

  def working_orders(store_id)
    orders = Order.working_orders store_id
    orders = combin_orders(orders)
    orders = order_by_status(orders)
    orders
  end
end