#encoding: utf-8
class OrderPayType < ActiveRecord::Base
  belongs_to :order

  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2, 
    :PACJAGE_CARD => 3, :SALE => 4, :IS_FREE => 5, :DISCOUNT_CARD => 6,:FAVOUR =>7,:CLEAR =>8,:HANG =>9} #0 现金  1 刷卡  2 储值卡   3 套餐卡  4  活动优惠  5免单
  PAY_TYPES_NAME = {0 => "现金", 1 => "刷卡", 2 => "储值卡", 3 => "套餐卡", 4 => "活动优惠", 5 => "免单", 6 => "打折卡",7=>"付款优惠",8=>"清零",9=>"挂账"}
  LOSS = [PAY_TYPES[:PACJAGE_CARD],PAY_TYPES[:SALE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  
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

  def self.deal_order(param)
    may_pay,card_price,msg,orders,is_billing = true,{},"",[],param[:billing].to_i
    if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
      store = Store.find param[:store_id]
      if store.limited_password.nil?  or store.limited_password == Digest::MD5.hexdigest(param[:pay_cash])
        may_pay,msg = false,"免单密码有误！"
      end
    end
    if may_pay && param[:pay_order] && param[:pay_order][:text]   #验证密码
      CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
        if c_relation.password != Digest::MD5.hexdigest(param[:pay_order][:"#{c_relation.id}"]) || c_relation.left_price < param[:pay_order][:text][:"#{c_relation.id}"].to_i
          may_pay,msg = false,"储值卡密码错误！"
        end
        use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_i
        card_price[c_relation.sv_card_id].nil? ?  card_price[c_relation.sv_card_id]=use_price : card_price[c_relation.sv_card_id] += use_price
      end
    end
    if may_pay   #如果密码正确
      CSvcRelation.transaction do
        sql = '1=1'
        #如果有退单
        if param[:pay_order] && param[:pay_order][:return_ids]
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
          order_ids,total_card = orders.map(&:id),0
          loss_orders = param[:pay_order] && param[:pay_order][:loss_ids] ?  param[:pay_order][:loss_ids] : {}
          clear_value = param[:pay_order] && param[:pay_order][:clear_value] ? param[:pay_order][:clear_value].to_i : 0
          order_pays = OrderPayType.search_pay_order(order_ids)
          prod_ids = OrderProdRelation.joins(:product).where(:order_id=>orders.map(&:id)).select("products.category_id c_id,order_id o_id").inject(Hash.new){
            |hash,o|hash[o.o_id]=o.c_id;hash}
          o_price = orders.inject(Hash.new){|hash,o|hash[o.id]= o.price-(loss_orders["#{o.id}"].nil? ? 0 : loss_orders["#{o.id}"].to_i)-(order_pays[o.id] ?  order_pays[o.id] : 0);hash}
          if param[:pay_order] && param[:pay_order][:text]   #如果使用储值卡
            sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:id=>param[:pay_order][:text].keys).
              select("c_svc_relations.*,sv_cards.name,sv_cards.store_id,svcard_prod_relations.category_id ci,sv_cards.id s_id").where("sv_cards.store_id=#{param[:store_id]}")
            is_suit = false
            sv_cards.each do |ca|
              t_price = 0
              orders.each do |o|
                t_price += o_price[o.id] if ca.ci.split(',').include? "#{prod_ids[o.id]}"
              end
              if card_price[ca.s_id] > t_price
                is_suit = true
              end
              total_card += card_price[ca.s_id]
            end
            if is_suit or (total_card+clear_value) > o_price.values.inject(0){|num,p|num+p}
              may_pay,msg = false,"储值卡付款超过可付额度！"
            end
          end
          if may_pay
            #如果有优惠
            if param[:pay_order] && param[:pay_order][:loss_ids]
              loss = param[:pay_order][:loss_ids]
              if param[:pay_order][:return_ids]
                loss = param[:pay_order][:loss_ids].select{|k,v| !param[:pay_order][:return_ids].include? k}
              end
              loss.each do |k,v|
                OrderPayType.create(:order_id=>k,:price=>v,:pay_type=>OrderPayType::PAY_TYPES[:FAVOUR])
              end unless loss.empty?
            end
            if param[:pay_order] && param[:pay_order][:text]   #使用储值卡更新储值卡余额，并将更新新买储值卡的状态
              CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
                use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_i
                only_price = c_relation.left_price - use_price
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
                  :left_price=>only_price,:content=>OrderProdRelation.order_products(order_ids).values.flatten.map(&:name).join("、"))
              end
            end
            cash_price = param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH].nil? ? 0 : param[:pay_cash].to_i - param[:second_parm].to_i
            orders.each do |o|
              if o_price[o.id] <= 0
                OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id]- total_card-clear_value,:pay_type=>param[:pay_type].to_i)
                o.update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT])
              else
                if o_price[o.id] <= total_card
                  OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id],:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD])
                  total_card -= o_price[o.id]
                  total_card=0 if total_card <0
                  o.update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT])
                else
                  if o_price[o.id] <= (total_card+clear_value)
                    OrderPayType.create(:order_id=>o.id,:price=>clear_value,:pay_type=>OrderPayType::PAY_TYPES[:CLEAR])
                    OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id]-clear_value,:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD])
                    total_card -= o_price[o.id]
                    clear_value = 0
                    total_card=0 if total_card <0
                  else
                    if clear_value>0
                      OrderPayType.create(:order_id=>o.id,:price=>clear_value,:pay_type=>OrderPayType::PAY_TYPES[:CLEAR])
                    end
                    if total_card >0
                      OrderPayType.create(:order_id=>o.id,:price=>total_card,:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD])
                    end
                    if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH]
                      OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id]- total_card-clear_value,:pay_type=>param[:pay_type].to_i,
                        :pay_cash=>param[:pay_cash],:second_parm=>param[:second_parm])
                      o.update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT])
                      cash_price -= (o_price[o.id]-total_card-clear_value)
                    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CREDIT_CARD]
                      o.update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT])
                      OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id]-total_card-clear_value,:pay_type=>param[:pay_type].to_i,:second_parm=>param[:second_parm])
                    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
                      o.update_attributes(:status=>Order::STATUS[:FINISHED])
                      OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id]-total_card-clear_value,:pay_type=>param[:pay_type].to_i)
                    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:HANG]  #挂账的话就把要付的钱设置为支付金额
                      o.update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT])
                      OrderPayType.create(:order_id=>o.id,:price=>o_price[o.id]-total_card-clear_value,:pay_type=>param[:pay_type].to_i)
                    end
                    clear_value = 0 if clear_value>0
                    total_card =0 if total_card >0
                  end
                end
              end
            end
            #新买储值卡但是未使用  新买打折卡  更新状态
            csvs = CSvcRelation.joins(:sv_card).select("*").where(:customer_id=>params[:customer_id],:order_id=>orders.map(&:id),:status=>CSvcRelation::STATUS[:invalid])
            csvs.update_all :status => CSvcRelation::STATUS[:valid], :is_billing => is_billing
            sv_used = []
            csvs.each do |csr|   #如果是新买储值卡则生成使用记录
              if csr.types == SvCard::FAVOR[:SAVE]
                sv_used << SvcardUseRecord.new(:c_svc_relation_id => csr.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,:left_price => csr.left_price, :content => "购买"+"#{csr.name}")
              end
            end
            SvcardUseRecord.import sv_used, :timestamps=>true unless sv_used.blank?
            CPcardRelation.where(:customer_id=>params[:customer_id],:order_id=>orders.map(&:id),:status=>CPcardRelation::STATUS[:INVALID]).update_all :status =>CPcardRelation::STATUS[:NORMAL]
          end
        end
      end
    end
    return  [may_pay,msg,orders.map(&:id)]
  end


  def check_pay_type(param)
    if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH]
      price = param[:pay_cash].to_i - param[:second_parm].to_i
      OrderPayType.create(:order_id=>orders,:price=>price,:pay_type=>OrderPayType::PAY_TYPES[:CASH],:pay_cash=>param[:pay_cash],:second_parm=>param[:second_parm])
    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CREDIT_CARD]
      OrderPayType.create(:order_id=>orders,:price=>param[:pay_cash],:pay_type=>OrderPayType::PAY_TYPES[:CREDIT_CARD],:pay_cash=>param[:pay_cash],:second_parm=>param[:second_parm])
    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
      @free = true
      if Store.find(param[:store_id]).limited_password == Digest::MD5.hexdigest(param[:pay_cash])
        @free = false
        orders = Order.where(:status=>Order::CASH,:store_id=>param[:store_id],:customer_id=>param[:customer_id],
          :car_num_id=>param[:car_num_id]).map(&:id)[0]
        OrderPayType.create(:order_id=>orders,:price=>param[:pay_cash],:pay_type=>OrderPayType::PAY_TYPES[:IS_FREE])
      end
    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:HANG]  #挂账的话就把要付的钱设置为支付金额
      OrderPayType.create(:order_id=>orders,:price=>param[:pay_cash],:pay_type=>OrderPayType::PAY_TYPES[:HANG])
    end
  end
  
end
