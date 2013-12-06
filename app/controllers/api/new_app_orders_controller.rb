#encoding: utf-8
require 'json'
require "uri"
class Api::NewAppOrdersController < ApplicationController

  #登录后返回数据
  def new_index_list
    #参数store_id
    status = 0
    #orders => 车位施工情况
    #订单分组
    work_orders = working_orders params[:store_id]
    #stations_count => 工位数目
    station_ids = Station.where("store_id =? and status not in (?) ",params[:store_id], [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
    services = Product.is_service.is_normal.commonly_used.where(:store_id => params[:store_id]).select("id, name, sale_price as price")

    render :json => {:status => status, :orders => work_orders, :station_ids => station_ids, :services => services}
  end

  #产品、服务、卡类搜索
  def search
    type = params[:search_type].to_i
    content = params[:search_text]
    #name = content.empty? || content=="" ? "and 1=1" : " and p.name like %#{content.gsub(/[%_]/){|x| '\\' + x}}%"
    store_id = params[:store_id].to_i
    result = []   
    sql = [""]
    if type==0  #如果是产品
      sql[0] = "select p.*, m.storage storage from categories c inner join products p on c.id=p.category_id
        inner join prod_mat_relations pmr on p.id=pmr.product_id
        inner join materials m on pmr.material_id=m.id
        where c.types=? and c.store_id=? and p.status=? and m.storage>0"
      sql << Category::TYPES[:good] << store_id << Product::IS_VALIDATE[:YES]
      unless content.nil? || content.empty? || content == ""
        sql[0] += " and p.name like ?"
        sql << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      goods = Product.find_by_sql(sql).uniq
      result = goods.inject([]){|h, g|
        a = {}
        a[:id] = g.id.to_s
        a[:name] = g.name
        a[:img_small] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[0]}")
        a[:img_big] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[1]}")
        a[:point] = g.prod_point.to_s
        a[:price] = g.sale_price.to_s
        a[:desc] = g.description
        a[:num] = g.storage.to_s
        h << a;
        h
      }
    elsif type==1 #如果是服务
      sql[0] = "select p.* from categories c inner join products p on c.id=p.category_id
        where c.types=? and c.store_id=? and p.status=?"
      sql << Category::TYPES[:service] << store_id << Product::IS_VALIDATE[:YES]
      unless content.nil? || content.empty? || content == ""
        sql[0] += " and p.name like ?"
        sql << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      services = Product.find_by_sql(sql)
      result = services.inject([]){|h, g|
        a = {}
        a[:id] = g.id.to_s
        a[:name] = g.name
        a[:img_small] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[0]}")
        a[:img_big] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[1]}")
        a[:point] = g.prod_point.to_s
        a[:price] = g.sale_price.to_s
        a[:desc] = g.description
        h << a;
        h
      }
    elsif type==2 #如果是卡类
      chains_id = StoreChainsRelation.find_by_sql(["select distinct(scr.chain_id) from store_chains_relations scr
      inner join chains c on scr.chain_id=c.id where scr.store_id = ? and c.status=?", store_id, Chain::STATUS[:NORMAL]])
      .map(&:chain_id)
      stores_id = StoreChainsRelation.find_by_sql(["select distinct(scr.store_id) from store_chains_relations scr
      inner join stores s on scr.store_id=s.id where scr.chain_id in (?) and s.status in (?)", chains_id,
          [Store::STATUS[:OPENED],Store::STATUS[:DECORATED]]]).map(&:store_id) #获取该门店所有的连锁店
      if stores_id.blank?   #若该门店无其他连锁店
        sql[0] = "select * from sv_cards where store_id = ? and status = ?"
        sql << store_id << SvCard::STATUS[:NORMAL]
      else    #若该门店有其他连锁店
        sql[0] = "select * from sv_cards where ((store_id=? and use_range=?) or (store_id in (?) and use_range = ?)) and
      status=?"
        sql << store_id << SvCard::USE_RANGE[:LOCAL] << stores_id << SvCard::USE_RANGE[:CHAINS] << SvCard::STATUS[:NORMAL]
      end
      unless content.nil? || content.empty? || content == ""
        sql[0] += " and name like ?"
        sql << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      sv_cards = SvCard.find_by_sql(sql)    #获取该门店的优惠卡及其同连锁店下面的门店的使用范围为连锁店的优惠卡
      sc_records = sv_cards.inject([]){|h, s|
        a = {}
        a[:id] = s.id.to_s
        a[:name] = s.name
        a[:img_small] = s.img_url.nil? ||  s.img_url.empty? ? "" : s.img_url.gsub("img#{s.id}", "img#{s.id}_#{Constant::SVCARD_PICSIZE[2]}")
        a[:img_big] = s.img_url.nil? ||  s.img_url.empty? ? "" : s.img_url.gsub("img#{s.id}", "img#{s.id}_#{Constant::SVCARD_PICSIZE[1]}")
        a[:price] = s.price.to_s
        a[:type] = s.types.to_s
        a[:desc] = s.description
        if s.types.to_i==SvCard::FAVOR[:SAVE] #如果是储值卡，则把冲xx送XX，可以在XX类下消费加入到描述中
          str = ""
          spr = SvcardProdRelation.find_by_sv_card_id(s.id)
          if spr
            ct = Category.find_by_sql(["select name from categories where id in (?)", spr.category_id.split(",")]).map(&:name)
            str += "充"+spr.base_price.to_s+"送"+spr.more_price.to_s+"\n"
            str += "适用类型：\n"
            pn = []
            ct.each do |c|
              pn << c
            end
            str += pn.join("\n")
          end
          a[:products] = pn
          a[:desc] = str
        else   #如果是打折卡，则要关联他的products以及对应的折扣
          str = "打折详情：\n"
          pids = SvcardProdRelation.where(["sv_card_id = ?", s.id]) #找到该打折卡关联的产品
          if pids
            spr = pids.inject({}){|h, s|h[s.product_id]=s.product_discount;h} #{1 => XXX折， 2 => XXX折}
            pname = Product.where(["id in (?)", pids.map(&:product_id).uniq]).inject({}){|h, p|h[p.id] = p.name;h} #{1 => "XXX", 2 => "XXX"}
            pn = []
            pn2 = []
            pname.each do |k, v|
              pn << v.to_s + "-" + (spr[k].to_i*0.1).to_s
              pn2 << {:name => v, :discount => (spr[k].to_i*0.1).to_s}
            end
            str += pn.join("\n")
            a[:products] = pn2
            a[:desc] = str
          end
        end
        h << a;
        h
      }

      #获取该门店所有的套餐卡及其所关联的物料
      sql2 = ["select p.* from package_cards p left join pcard_material_relations pmr
        on p.id=pmr.package_card_id left join materials m on pmr.material_id=m.id  and m.storage>0
        where p.store_id=? and ((p.date_types=?) or (p.date_types=? and NOW()<=p.ended_at)) and p.status=?",
        store_id, PackageCard::TIME_SELCTED[:END_TIME],
        PackageCard::TIME_SELCTED[:PERIOD], PackageCard::STAT[:NORMAL]]
      unless content.nil? || content.empty? || content == ""
        sql2[0] += " and p.name like ?"
        sql2 << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      p_cards = PackageCard.find_by_sql(sql2)
      p "*************"
      p p_cards.length
      p_records = []
      if p_cards
        p_records = p_cards.inject([]){|h, p|
          str2 = "套餐内容：\n"
          a = {}
          a[:id] = p.id.to_s
          a[:name] = p.name.to_s
          a[:img_small] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::SVCARD_PICSIZE[2]}")
          a[:img_big] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::SVCARD_PICSIZE[1]}")
          a[:price] = p.price.to_s
          a[:type] = "2"
          a[:point] = p.prod_point.to_s
          name_and_num = PcardProdRelation.find_by_sql(["select ppr.product_num, p.name from pcard_prod_relations ppr inner join products p on
         ppr.product_id=p.id where ppr.package_card_id=?", p.id])
          str2 += name_and_num.inject([]){|h, n|h << n.name.to_s+"-"+n.product_num.to_s+"次";h}.join("\n") if name_and_num
          
          a[:products] = name_and_num.inject([]){|h, n|h << {:name => n.name.to_s, :num => n.product_num.to_s};h} if name_and_num
          a[:desc] = str2
          h << a;
          h
        }
      end
      result = [sc_records + p_records].flatten
    end
    if result.blank?
      status = 0
      msg = "没有找到符合条件的记录"
    else
      status = 1
      msg = "查找成功!"
    end
    render :json => {:status => status, :msg => msg, :result => result}
  end

  #生成订单
  def make_order
    #参数params[:content]类型：id_count_search_type_type(选择的商品id_数量_产品/服务/卡_储值卡/打折卡/套餐卡)
    pram_str = params[:content].split("-") if params[:content]
    status = 1
    msg = ""
    is_new_cus = 0
    Customer.transaction do
      customer = CarNum.get_customer_info_by_carnum(params[:store_id], params[:num])
      if customer   #如果不是新的车牌
        #该用户所购买的打折卡及其所支持的产品或服务
        sv_cards = CSvcRelation.get_customer_discount_cards(customer.customer_id,params[:store_id])
        #该用户所购买的套餐卡及其所支持的产品或服务
        p_cards = CPcardRelation.get_customer_package_cards(customer.customer_id, params[:store_id])
      else          #如果是新的车牌，则要创建一个空白的客户和车牌，以及客户-门店、客户-车牌关联记录
        customer = Customer.create(:status => Customer::STATUS[:NOMAL])
        car_num = CarNum.create(:num => params[:num])
        customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
        relation = CustomerStoreRelation.find_by_store_id_and_customer_id(params[:store_id], customer.id)
        customer.customer_store_relations.create({:customer_id => customer.id, :store_id => params[:store_id]}) unless relation
        customer.save
        is_new_cus = 1
      end

      #获取所有的车品牌/型号
      capital_arr = Capital.get_all_brands_and_models

      #产生订单
      if pram_str[2].to_i != 2    #如果选的是产品或服务
        product = Product.find_by_id_and_status(pram_str[0].to_i, Product::IS_VALIDATE[:YES])
 

        if product.types == Product::PROD_TYPES[:SERVICE] #如果选的是服务，则要查看工位情况
          time_arr = Station.arrange_time params[:store_id], [product.id], nil, nil
          case time_arr[1]
          when 0
            station_status = 2 #没工位
            msg = ""
          when 1
            station_status = 1  #有符合工位
            msg = ""

          when 2
            station_status = 3 #多个工位
          when 3
            station_status = 4 #工位上暂无技师
          end
      
        end
      else    #如果选的是卡类
        if  pram_str[3].to_i == 0 || pram_str[3].to_i == 1    #如果选的是打折卡或储值卡
          sc = SvCard.find_by_id(pram_str[0].to_i)
          order = Order.create({
              :code => MaterialOrder.material_order_code(params[:store_id].to_i),
              :car_num_id => is_new_cus==0 ? customer.car_num_id : car_num.id,
              :status => Order::STATUS[:NORMAL],
              :price => sc.price,
              :is_billing => false,
              :front_staff_id => params[:user_id],
              :customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
              :store_id => params[:store_id],
              :is_visited => Order::IS_VISITED[:NO],
              :types => Order::TYPES[:SERVICE]
            })
          CSvcRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id, :sv_card_id => sc.id,
            :is_billing => false, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid])
          if sc.types == SvCard::FAVOR[:DISCOUNT]
            items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", sc.sid])
            items.each do |i|
              hash = {}
              hash[:pid] = i.id
              hash[:pname] = i.name
              hash[:pprice] = i.sale_price
              hash[:pdiscount] = i.product_discount
            end
            sv_cards << {:svid => sc.id, :svname => sc.name, :svprice => sc.price, :is_new => 1, :svproducts => hash}
          end
        else  #如果选的是套餐卡
          pc = PackageCard.find_by_id(pram_str[0].to_i)
          order = Order.create({
              :code => MaterialOrder.material_order_code(params[:store_id].to_i),
              :car_num_id => is_new_cus==0 ? customer.car_num_id : car_num.id,
              :status => Order::STATUS[:NORMAL],
              :price => pc.price,
              :is_billing => false,
              :front_staff_id => params[:user_id],
              :customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
              :store_id => params[:store_id],
              :is_visited => Order::IS_VISITED[:NO],
              :types => Order::TYPES[:SERVICE]
            })
          pitems = PcardProdRelation.find_by_sql(["select pp.product_num num, p.name name,p.id id from pcard_prod_relations ppr inner join
              products p on ppr.product_id=p.id where ppr.package_card_id=?", pc.id])
          pstr = ""
          b = []
          c = []
          pitems.each do |pi|
            b << pi.id.to_s+"-"+pi.name.to_s+"-"+pi.num
            c << {:pid => pi.id, :pname => pi.name, :left_count => pi.num}
          end
          pstr = b.join(",")
          CPcardRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id, :package_card_id => pc.id,
            :status => CPcardRelation::STATUS[:INVALID], :price => pc.price, :order_id => order.id, :content => pstr)
          p_cards << {:pid => pc.id, :pname => pc.name, :pprice => pc.price, :is_new => 1, :pproducts => c}
        end
      end
      render :json => {:status => station_status}
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
          station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i if station_id
          if station_staffs
            staff_id_1 = station_staffs[0].staff_id if station_staffs.size > 0
            staff_id_2 = station_staffs[1].staff_id if station_staffs.size > 1
          end
          order = wo.order
          order.update_attributes(:cons_staff_id_1 =>staff_id_1,:cons_staff_id_2 => staff_id_2) if order
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
      status = work_order.status==WorkOrder::STAT[:WAIT_PAY]? 0 : 1
      #0:"此车等待付款"1:未付款
      work_order.arrange_station
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
    orders = new_app_order_by_status(orders)
    orders
  end
end