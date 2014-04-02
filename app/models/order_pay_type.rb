#encoding: utf-8
class OrderPayType < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2, 
    :PACJAGE_CARD => 3, :SALE => 4, :IS_FREE => 5, :DISCOUNT_CARD => 6,:FAVOUR =>7,:CLEAR =>8,:HANG =>9} #0 现金  1 刷卡  2 储值卡   3 套餐卡  4  活动优惠  5免单
  PAY_TYPES_NAME = {0 => "现金", 1 => "银行卡", 2 => "储值卡", 3 => "套餐卡", 4 => "活动优惠", 5 => "免单", 6 => "打折卡",7=>"优惠",8=>"抹零",9=>"挂账"}
  LOSS = [PAY_TYPES[:SALE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  PAY_STATUS = {:UNCOMPLETE =>1,:COMPLETE =>0} #1 挂账未结账  0  已结账
  FAVOUR = [PAY_TYPES[:SALE],PAY_TYPES[:IS_FREE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  FINCANCE_TYPES = {0 => "现金", 1 => "银行卡", 2 => "储值卡", 3 => "套餐卡", 5 => "免单", 6 => "打折卡",9=>"挂账"}
  
  def self.order_pay_types(orders)
    return OrderPayType.find(:all, :conditions => ["order_id in (?)", orders]).inject(Hash.new){|hash,t|
      hash[t.order_id].nil? ? hash[t.order_id] = [PAY_TYPES_NAME[t.pay_type]] : hash[t.order_id] << PAY_TYPES_NAME[t.pay_type];
      hash[t.order_id]=hash[t.order_id].uniq;hash}
  end

  def self.search_pay_order(orders)
    OrderPayType.select(" ifnull(sum(price),0) sum,order_id").where(:order_id=>orders).group('order_id').inject(Hash.new){
      |hash,o| hash[o.order_id]=o.sum;hash}
  end

  def self.search_pay_types(orders)
    OrderPayType.select(" ifnull(sum(price),0) sum,pay_type").where(:order_id=>orders).group('pay_type').inject(Hash.new){
      |hash,o|hash[o.pay_type]=o.sum;hash}
  end

  def self.pay_order_types(orders)
    OrderPayType.select(" ifnull(sum(price),0) sum,order_id,pay_type").where(:order_id=>orders).group('order_id,pay_type').inject(Hash.new){
      |hash,o| hash[o.order_id].nil? ? hash[o.order_id]={o.pay_type=>o.sum} : hash[o.order_id][o.pay_type]=o.sum;hash}
  end

  #保留金额的两位小数
  def self.limit_float(num)
    return ((num.to_f*100).to_i/100.0).round(2)
  end

  def self.deal_order(param)
    customer = Customer.where(:store_id=>param[:store_id],:customer_id=>param[:customer_id]).first
    is_vip,may_pay = false,true
    order_pay_types,orders,svcard_use_record = [],[],[]
    card_price,msg,is_billing = {},"付款成功！",param[:pay_order][:is_billing].to_i
    if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
      store = Store.find param[:store_id]
      if store.limited_password.nil?  or store.limited_password != Digest::MD5.hexdigest(param[:pay_cash])
        may_pay,msg = false,"免单密码有误！"
      end
    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:HANG]
      if customer.allowed_debts == Customer::ALLOWED_DEBTS[:NO]
        may_pay,msg = false,"该客户不允许挂账！"
      else
        pay_type = OrderPayType.joins(:order=>:customer).select("ifnull(sum(order_pay_types.price),0) total_price,
        ifnull(min(date_format(order_pay_types.created_at,'%Y-%m-%d')),date_format(now(),'%Y-%m-%d')) min_time").where(
          :pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
          :"orders.customer_id"=>param[:customer_id],:"orders.store_id"=>param[:store_id]).first
        time = customer.check_type == Customer::CHECK_TYPE[:MONTH] ? pay_type.min_time.to_date+customer.check_time.months : pay_type.min_time.to_date+customer.check_time.weeks
        if Time.now > time
          may_pay,msg = false,"上一个周期未付款，不能挂账！"
        elsif customer.debts_money < limit_float(param[:pay_cash].to_f + pay_type.total_price.to_f)
          may_pay,msg = false,"挂账额度余额为#{(customer.debts_money-pay_type.total_price.to_f).round(2)}！"
        end
      end
    end
    if may_pay && param[:pay_order] && param[:pay_order][:text]   #验证密码
      CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
        if c_relation.password != Digest::MD5.hexdigest(param[:pay_order][:"#{c_relation.id}"]) || c_relation.left_price < param[:pay_order][:text][:"#{c_relation.id}"].to_f
          may_pay,msg = false,"储值卡密码错误！"
        end
        use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_f
        card_price[c_relation.sv_card_id].nil? ?  card_price[c_relation.sv_card_id]=use_price : card_price[c_relation.sv_card_id] += use_price
      end
    end
    if may_pay   #如果密码正确
      OrderPayType.transaction do
        sql = '1=1'
        if param[:pay_order] && param[:pay_order][:return_ids]  #如果有退单
          sql += " and id not in (#{param[:pay_order][:return_ids].join(',')})"
          return_orders = Order.where(:id=>param[:pay_order][:return_ids])
          return_orders.update_all(:status=>Order::STATUS[:RETURN],:return_types=>Order::IS_RETURN[:YES])
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
          order_ids,total_card,sort_orders,is_suit,messages = orders.map(&:id),0,[],false,[]
          total_name,warn,revist,sv_prod,send_orders,customer_p,order_points = {},{},{},{},{},{},{}
          send_orders = orders.inject({}){|h,o|h[o.id]=o;h}
          cprs = CPcardRelation.joins(:package_card).select("*").where(:customer_id=>param[:customer_id],:order_id=>order_ids,
            :status=>CPcardRelation::STATUS[:INVALID])
          loss_orders = param[:pay_order] && param[:pay_order][:loss_ids] ?  param[:pay_order][:loss_ids] : {}
          clear_value = param[:pay_order] && param[:pay_order][:clear_value] ? param[:pay_order][:clear_value].to_f : 0
          order_pays = OrderPayType.search_pay_order(order_ids)
          prods = OrderProdRelation.joins(:product).where(:order_id=>orders.map(&:id)).select("products.category_id c_id,order_id o_id,product_id p_id,pro_num,name,revist_content")
          prod_ids = prods.inject(Hash.new){|hash,o|hash[o.o_id]=o.c_id;hash}
          order_prod_ids = prods.inject({}){|h,p|h[p.o_id]=p;h}
          prods.group_by{|i|i.o_id}.each{|k,v|revist[k] = v.map(&:revist_content).compact unless send_orders[k].auto_time.nil?}
          pcard_name = cprs.inject({}){|hash,p|hash[p.order_id] = p.name;hash} #套餐卡名称
          cprs.group_by{|i|i.order_id}.each{|k,v|revist[k] = v.map(&:revist_content).compact unless send_orders[k].auto_time.nil? ;warn[k]=v.map(&:con_warn).compact unless send_orders[k].warn_time.nil?}
          o_price = orders.inject(Hash.new){|hash,o|hash[o.id]= limit_float(o.price-(loss_orders["#{o.id}"].nil? ? 0 : loss_orders["#{o.id}"].to_f)-(order_pays[o.id] ?  order_pays[o.id] : 0));hash}
          if param[:pay_order] && param[:pay_order][:text]   #如果使用储值卡
            sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:id=>param[:pay_order][:text].keys).select("c_svc_relations.*,
            sv_cards.name,sv_cards.store_id,svcard_prod_relations.category_id ci,svcard_prod_relations.pcard_ids pid,sv_cards.id s_id").where("sv_cards.store_id=#{param[:store_id]}")
            sv_pcard = cprs.inject({}){|h,p|h[p.order_id]=p.package_card_id;h}
            sv_cards.each do |ca|
              t_price = 0
              orders.each do |o|
                if (ca.ci and ca.ci.split(',').include? "#{prod_ids[o.id]}") or (ca.pid and ca.pid.split(',').include? "#{sv_pcard[o.id]}")
                  t_price += o_price[o.id]
                  sort_orders << o
                  sv_prod[o.id].nil? ? sv_prod[o.id] = [ca.id] : sv_prod[o.id] << ca.id
                end
              end
              if card_price[ca.s_id] > t_price
                is_suit = true
                break
              end
              total_card = limit_float(total_card+card_price[ca.s_id])
            end
            if is_suit or (total_card+clear_value) > (o_price.values.inject(0){|num,p|num+p})
              may_pay,msg = false,"储值卡付款超过可付额度！"
            end
          end
          if may_pay
            if param[:pay_order] && param[:pay_order][:loss_ids]  #如果有优惠
              loss = param[:pay_order][:loss_ids]
              if param[:pay_order][:return_ids]
                loss = param[:pay_order][:loss_ids].select{|k,v| !param[:pay_order][:return_ids].include? k}
              end
              loss.each do |k,v|
                order_pay_types <<  OrderPayType.new(:order_id=>k,:price=>v.to_f.round(2),:pay_type=>OrderPayType::PAY_TYPES[:FAVOUR])
              end unless loss.empty?
            end
            cash_price = param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH].nil? ? 0 : limit_float(param[:pay_cash].to_f - param[:second_parm].to_f)
            orders = sort_orders | (orders - sort_orders)
            #统计订单中  提成 和积分
            deducts = cprs.inject({}){|hash,c|hash[c.order_id] =[c.deduct_price+c.deduct_percent,0];order_points[c.order_id]=c.prod_point;hash}
            Order.joins(:order_prod_relations=>:product).select("ifnull(sum((deduct_price+deduct_percent)*pro_num),0) d_sum,
            ifnull(sum((techin_price+techin_percent)*pro_num),0) t_sum,sum(products.prod_point*order_prod_relations.pro_num) point,orders.id o_id").
              where(:"orders.id"=>order_ids).group('orders.id').each{|order|
              deducts[order.o_id] = deducts[order.o_id].nil? ? [order.d_sum,order.t_sum] : [deducts[order.o_id][0]+order.d_sum,order.t_sum]
              order_points[order.o_id] = order_points[order.o_id].nil? ? order.point : order_points[order.o_id]+order.point
            } #分别表示销售提成和技师提成

            orders.each do |o|
              pp = {:product_id => order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].p_id,
                :product_num => order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].pro_num}
              order_parm = {:is_billing => is_billing,:status=>Order::STATUS[:BEEN_PAYMENT]}
              price = o_price[o.id].to_f.round(2)
              if price > 0
                if price <= total_card
                  order_pay_types <<  OrderPayType.new({:order_id=>o.id,:price=>price,:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD]}.merge(pp))
                  sv_prod[o.id].each do |ca|
                    name = order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].name
                    total_name[ca].nil? ? total_name[ca] =[name] : total_name[ca] << name
                    total_name[ca].nil? ? total_name[ca] =[pcard_name[o.id]] : total_name[ca] << pcard_name[o.id]
                  end unless sv_prod[o.id].nil?
                  total_card = limit_float(total_card-price)
                  total_card=0 if total_card <0
                else
                  if price <= (total_card+clear_value)
                    #                    OrderPayType.create({:order_id=>o.id,:price=>limit_float(clear_value),:pay_type=>OrderPayType::PAY_TYPES[:CLEAR]}.merge(pp))
                    order_pay_types <<  OrderPayType.new({:order_id=>o.id,:price=>limit_float(price-clear_value),:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD]}.merge(pp))
                    sv_prod[o.id].each do |ca|
                      name = order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].name
                      total_name[ca].nil? ? total_name[ca] =[name] : total_name[ca] << name
                      total_name[ca].nil? ? total_name[ca] =[pcard_name[o.id]] : total_name[ca] << pcard_name[o.id]
                    end unless sv_prod[o.id].nil?
                    total_card = limit_float(total_card-price)
                    clear_value = 0
                    total_card=0 if total_card <0
                  else
                    if clear_value>0
                      order_pay_types <<  OrderPayType.new({:order_id=>o.id,:price=>clear_value,:pay_type=>OrderPayType::PAY_TYPES[:CLEAR]}.merge(pp))
                    end
                    if total_card >0
                      order_pay_types <<  OrderPayType.new({:order_id=>o.id,:price=>total_card,:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD]}.merge(pp))
                      sv_prod[o.id].each do |ca|
                        name = order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].name
                        total_name[ca].nil? ? total_name[ca] =[name] : total_name[ca] << name
                        total_name[ca].nil? ? total_name[ca] =[pcard_name[o.id]] : total_name[ca] << pcard_name[o.id]
                      end unless sv_prod[o.id].nil?
                    end
                    parms = {:order_id=>o.id,:price=>limit_float(price-total_card-clear_value),:pay_type=>param[:pay_type].to_i}
                    if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH]
                      parms.merge!(:pay_cash=>param[:pay_cash],:second_parm=>param[:second_parm])
                      cash_price = limit_float(cash_price-(price-total_card-clear_value))
                    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CREDIT_CARD]
                      parms.merge!(:second_parm=>param[:second_parm])
                    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
                      parms.merge!(pp)
                      order_parm[:status]=Order::STATUS[:FINISHED]
                    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:HANG]  #挂账的话就把要付的钱设置为支付金额
                      parms.merge!(:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE])
                    end
                    order_pay_types <<  OrderPayType.new(parms)
                    clear_value = 0 if clear_value>0
                    total_card =0 if total_card >0
                  end
                end
              end
              if deducts[o.id]
                deduct = {:front_deduct => deducts[o.id][0],:technician_deduct => deducts[o.id][1]}
                tech_orders =  o.tech_orders
                tech_orders.update_all(:own_deduct =>deduct[:technician_deduct]/tech_orders.length ) unless tech_orders.blank?
              end
              work_order = o.work_orders[0]
              if work_order && work_order.status == WorkOrder::STAT[:WAIT_PAY]
                work_order.update_attributes(:status=>WorkOrder::STAT[:COMPLETE])
              end
              o.update_attributes(order_parm.merge!(deduct)) #更新订单 提成 等信息
            end   #更新完订单状态

            if param[:pay_order] && param[:pay_order][:text]   #使用储值卡更新储值卡余额，并将更新新买储值卡的状态
              CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
                use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_f
                only_price = limit_float(c_relation.left_price - use_price)
                pars = {:left_price=>only_price}
                if c_relation.sv_card.status == SvCard::STATUS[:DELETED]
                  if only_price > 0
                    pars.merge!(:status=>CSvcRelation::STATUS[:valid])
                  end
                else
                  pars.merge!(:status=>CSvcRelation::STATUS[:invalid]) if only_price <= 0
                end
                c_relation.update_attributes(pars)
                SvcardUseRecord.create(:c_svc_relation_id=>c_relation.id,:types=>SvcardUseRecord::TYPES[:OUT],:use_price=>use_price,
                  :left_price=>only_price,:content=>total_name[c_relation.id].nil? ? "" : total_name[c_relation.id].compact.uniq.join("、"))
              end
            end
            #新买打折卡 储值卡 更新状态为可用
            CSvcRelation.select("*").where(:customer_id=>param[:customer_id],:order_id=>orders.map(&:id),:status=>CSvcRelation::STATUS[:invalid]).update_all :status => CSvcRelation::STATUS[:valid], :is_billing => is_billing
            #如果是新买储值卡则生成购买记录
            CSvcRelation.joins(:sv_card).select("*").where(:customer_id=>param[:customer_id],:order_id=>orders.map(&:id),:status=>CSvcRelation::STATUS[:invalid],:"sv_cards.types"=>SvCard::FAVOR[:SAVE]).each {|csr|
              svcard_use_record <<   SvcardUseRecord.new(:c_svc_relation_id => csr.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,:left_price =>csr.left_price.round(2), :content => "购买"+"#{csr.name}")
              is_vip = true
            } 
            SvcardUseRecord.import svcard_use_record unless svcard_use_record.blank?
            if (customer && customer.is_vip) || is_vip    #积分  积分记录
              points = order_points.values.compact.inject(0){|sum,n|sum+n}
              customer.update_attributes({:total_point=>points+customer.total_point,:is_vip=>is_vip})
              t_point = order_points.inject([]){|arr,p| arr << Point.new(:customer_id=>param[:customer_id],
                  :target_id=>p[0],:target_content=>"购买产品/服务/套餐卡获得积分",:point_num=>p[1],:types=>Point::TYPES[:INCOME]) }
              Point.import t_point  unless t_point.blank?
            end
            #生成出库记录
            order_mat_infos = Order.joins(:order_prod_relations=>{:product=>{:prod_mat_relations=>:material}}).select("material_id m_id,
            front_staff_id f_id,material_num m_num,materials.price m_price").where(:"products.is_service"=>Product::PROD_TYPES[:PRODUCT],
              :"orders.id"=>order_ids)
            mat_outs = order_mat_infos.inject([]){|arr,m| arr << MatOutOrder.new({:material_id =>m.m_id, :staff_id =>m.f_id,
                  :material_num => m.m_num,:price => m.m_price, :types => MatOutOrder::TYPES_VALUE[:sale], :store_id =>param[:store_id]})}
            MatOutOrder.import mat_outs unless mat_outs.blank?
            CPcardRelation.where(:customer_id=>param[:customer_id],:order_id=>orders.map(&:id),:status=>CPcardRelation::STATUS[:INVALID]).update_all :status =>CPcardRelation::STATUS[:NORMAL]
            #设置订单中的提醒和回访
            customer_p = Customer.find(orders.map(&:customer_id)).inject({}){|h,c|h[c.id]=c.mobilephone;h}
            warn.each {|k,v|order = send_orders[k];messages << SendMessage.new({:content=>v.join('\n'),:customer_id=>order.customer_id,:types=>SendMessage::TYPES[:WARN],
                  :car_num_id=>order.car_num_id,:phone=>customer_p[order.customer_id],:send_at=>order.warn_time,:status=>SendMessage::STATUS[:WAITING],:store_id=>order.store_id})}
            revist.each {|k,v|order = send_orders[k];messages << SendMessage.new({:content=>v.join('\n'),:customer_id=>order.customer_id,:types=>SendMessage::TYPES[:REVIST],
                  :car_num_id=>order.car_num_id,:phone=>customer_p[order.customer_id],:send_at=>order.auto_time,:status=>SendMessage::STATUS[:WAITING],:store_id=>order.store_id})}
            SendMessage.import messages  unless messages.blank?
          end
        end
      end
    end
    return  [may_pay,msg,orders.map(&:id)]
  end
end
