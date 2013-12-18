#encoding: utf-8
class OrderPayType < ActiveRecord::Base
  belongs_to :order

  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2, 
    :PACJAGE_CARD => 3, :SALE => 4, :IS_FREE => 5, :DISCOUNT_CARD => 6,:FAVOUR =>7,:CLEAR =>8,:HANG =>9} #0 现金  1 刷卡  2 储值卡   3 套餐卡  4  活动优惠  5免单
  PAY_TYPES_NAME = {0 => "现金", 1 => "刷卡", 2 => "储值卡", 3 => "套餐卡", 4 => "活动优惠", 5 => "免单", 6 => "打折卡",7=>"付款优惠",8=>"清零",9=>"挂账"}
  LOSS = [PAY_TYPES[:PACJAGE_CARD],PAY_TYPES[:SALE],PAY_TYPES[:DISCOUNT_CARD]]
  
  def self.order_pay_types(orders)
    return OrderPayType.find(:all, :conditions => ["order_id in (?)", orders]).inject(Hash.new){|hash,t|
      hash[t.order_id].nil? ? hash[t.order_id] = [PAY_TYPES_NAME[t.pay_type]] : hash[t.order_id] << PAY_TYPES_NAME[t.pay_type];
      hash[t.order_id]=hash[t.order_id].uniq;hash}
  end

  def self.search_pay_order(orders)
    OrderPayType.select(" ifnull(sum(price), 0)  sum,order_id").where(:order_id=>orders).group('order_id').inject(Hash.new){
      |hash,o| hash[o.order_id]=o.sum;hash}
  end


  def self.deal_order(param,order_status)
    may_pay = true
    if param[:pay_order][:text]   #验证密码
      CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
        if c_relation.password != Digest::MD5.hexdigest(param[:pay_order][:"#{c_relation.id}"]) || c_relation.left_price < param[:pay_order][:text][:"#{c_relation.id}"].to_i
          may_pay = false
        end
      end
    end
    if may_pay   #如果密码正确
      CSvcRelation.transaction do
        sql = '1=1'
        #如果有退单
        if param[:pay_order][:return_ids]
          sql += " and id not in (#{param[:pay_order][:return_ids].join(',')})"
          return_orders = Order.where(:id=>param[:pay_order][:return_ids])
          return_orders.update_all(:status=>Order::STATUS[:RETURN])
          return_orders.each do|order|
            #如果是套餐卡退回使用次数
            order.return_order_pacard_num
            #退回产品或者服务相关物料数量
            order.return_order_materials
            order.rearrange_station
          end
        end
        orders = Order.where(:status=>Order::CASH,:store_id=>param[:store_id],:customer_id=>param[:customer_id],
          :car_num_id=>param[:car_num_id]).where(sql)
        unless orders.blank?
          order_ids = orders.map(&:id)
          #如果有优惠
          if param[:pay_order][:loss_ids]
            loss = param[:pay_order][:loss_ids]
            if param[:pay_order][:return_ids]
              loss = param[:pay_order][:loss_ids].select{|k,v| !param[:pay_order][:return_ids].include? k}
            end
            loss.each do |k,v|
              OrderPayType.create(:order_id=>k,:price=>v,:pay_type=>OrderPayType::PAY_TYPES[:FAVOUR])
            end unless loss.empty?
          end
          if param[:pay_order][:clear_value] && order_ids.length>=1
            OrderPayType.create(:order_id=>order_ids[0],:price=>param[:pay_order][:clear_value],:pay_type=>OrderPayType::PAY_TYPES[:CLEAR])
          end
          orders.update_all(:status=>order_status)
          if param[:pay_order][:text]
            CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
              use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_i
              only_price = c_relation.left_price - use_price
              pars = {:left_price=>only_price}
              pars.merge!(:status=>CSvcRelation::STATUS[:invalid]) if (only_price <=0)
              c_relation.update_attributes(pars)
              OrderPayType.create(:order_id=>order_ids[0],:price=>use_price,:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD])
              SvcardUseRecord.create(:c_svc_relation_id=>c_relation.id,:types=>SvcardUseRecord::TYPES[:OUT],:use_price=>use_price,
                :left_price=>only_price,:content=>OrderProdRelation.order_products(order_ids).values.flatten.map(&:name).join("、"))
            end
          end
        end
      end
    end
    return  may_pay
  end
  
end
