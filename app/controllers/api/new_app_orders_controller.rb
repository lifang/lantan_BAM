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
        a[:img_big] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[5]}")
        a[:point] = g.prod_point.to_s
        a[:price] = g.sale_price.to_s
        a[:desc] = g.description
        a[:num] = g.storage.to_s
        h << a;
        h
      }
    elsif type==1 #如果是服务
      sql[0] = "select p.* from categories c inner join products p on c.id=p.category_id
        where c.types=? and c.store_id=? and p.status=? and p.single_types=?"
      sql << Category::TYPES[:service] << store_id << Product::IS_VALIDATE[:YES] << Product::SINGLE_TYPE[:SIN]
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
        a[:img_big] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[5]}")
        a[:point] = g.prod_point.to_s
        a[:price] = g.sale_price.to_s
        a[:desc] = g.description
        pmr = ProdMatRelation.find_by_sql(["select pmr.material_num num,m.storage from prod_mat_relations pmr left join materials m on
            pmr.material_id=m.id and m.storage>0 where pmr.product_id=?", g.id])
        array = []
        pmr.each do |pm|
          array << pm.storage.to_i / pm.num
        end if pmr
        a[:num] = array.min
        if a[:num].nil?
          a[:num] = -1
          h << a
        elsif a[:num] > 0
          h << a
        end;
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
        a[:img_big] = s.img_url.nil? ||  s.img_url.empty? ? "" : s.img_url.gsub("img#{s.id}", "img#{s.id}_#{Constant::SVCARD_PICSIZE[3]}")
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
          str = ""
          pids = SvcardProdRelation.where(["sv_card_id = ?", s.id]) #找到该打折卡关联的产品
          if pids
            spr = pids.inject({}){|h, s|h[s.product_id]=s.product_discount;h} #{1 => XXX折， 2 => XXX折}
            pname = Product.where(["id in (?)", pids.map(&:product_id).uniq]).inject({}){|h, p|h[p.id] = p.name;h} #{1 => "XXX", 2 => "XXX"}
            pn = []
            pn2 = []
            pname.each do |k, v|
              pn << v.to_s + "-" + (spr[k].to_i*0.1).to_s+"折"
              pn2 << {:name => v, :discount => (spr[k].to_i*0.1).to_s+"折"}
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
      sql2 = ["select p.* from package_cards p 
        where p.store_id=? and ((p.date_types=?) or (p.date_types=? and NOW()<=p.ended_at)) and p.status=?",
        store_id, PackageCard::TIME_SELCTED[:END_TIME],
        PackageCard::TIME_SELCTED[:PERIOD], PackageCard::STAT[:NORMAL]]
      unless content.nil? || content.empty? || content == ""
        sql2[0] += " and p.name like ?"
        sql2 << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      p_cards = PackageCard.find_by_sql(sql2)
      p_records = []
      if p_cards
        p_records = p_cards.inject([]){|h, p|
          str2 = ""
          a = {}
          a[:id] = p.id.to_s
          a[:name] = p.name.to_s
          a[:img_small] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::C_PICSIZE[2]}")
          a[:img_big] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::C_PICSIZE[3]}")
          a[:price] = p.price.to_s
          a[:type] = "2"
          a[:point] = p.prod_point.to_s
          name_and_num = PcardProdRelation.find_by_sql(["select ppr.product_num, p.name from pcard_prod_relations ppr inner join products p on
         ppr.product_id=p.id where ppr.package_card_id=?", p.id])
          str2 += name_and_num.inject([]){|h, n|h << n.name.to_s+"-"+n.product_num.to_s+"次";h}.join("\n") if name_and_num       
          a[:products] = name_and_num.inject([]){|h, n|h << {:name => n.name.to_s, :num => n.product_num.to_s+"次"};h} if name_and_num
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
  def make_order2
    #参数params[:content]类型：id_count_search_type_type(选择的商品id_数量_产品/服务/卡_储值卡/打折卡/套餐卡)
    pram_str = params[:content].split("-") if params[:content]
    status = 1
    msg = ""
    sv_cards = []
    p_cards = []
    sales = []
    Customer.transaction do
      customer = CarNum.get_customer_info_by_carnum(params[:store_id], params[:num])
      is_new_cus = 0
      if customer.nil?
        #如果是新的车牌，则要创建一个空白的客户和车牌，以及客户-门店、客户-车牌关联记录
        customer = Customer.create(:status => Customer::STATUS[:NOMAL], :property => Customer::PROPERTY[:PERSONAL],
          :allowed_debts => Customer::ALLOWED_DEBTS[:NO])
        car_num = CarNum.create(:num => params[:num])
        customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
        relation = CustomerStoreRelation.find_by_store_id_and_customer_id(params[:store_id], customer.id)
        customer.customer_store_relations.create({:customer_id => customer.id, :store_id => params[:store_id]}) unless relation
        customer.save
        is_new_cus = 1
      end
           
      #创建订单
      if pram_str[2].to_i != 2  #如果是产品或者服务
        if is_new_cus == 0
          #该用户所购买的打折卡及其所支持的产品或服务
          sv_cards = CSvcRelation.get_customer_discount_cards(customer.customer_id,params[:store_id].to_i)
          #该用户所购买的套餐卡及其所支持的产品或服务
          p_cards = CPcardRelation.get_customer_package_cards(customer.customer_id, params[:store_id].to_i)
          #该用户所购买的储值卡及其所支持的产品或服务类型
          save_cards = CSvcRelation.get_customer_supposed_save_cards(customer.customer_id, params[:store_id].to_i, pram_str[0].to_i)
        end
        create_result = OrderProdRelation.make_record(pram_str[0].to_i, pram_str[1].to_i, params[:user_id].to_i,
          is_new_cus == 0 ? customer.customer_id : customer.id,  is_new_cus == 0 ? customer.car_num_id : car_num.id, params[:store_id].to_i)
        status = create_result[0]
        msg = create_result[1]
        product = create_result[2]
        order = create_result[3]
        #获取所有该产品相关的活动
        s = Order.get_sale_by_product(product, order.car_num_id) if product
        sales = s
      else  #如果选的是卡类
        if pram_str[3].to_i == 0 || pram_str[3].to_i == 1    #如果选的是打折卡或储值卡
          card = SvCard.find_by_id(pram_str[0].to_i)
        else
          card = PackageCard.find_by_id(pram_str[0].to_i)
        end
        if card
          order = Order.create({
              :code => MaterialOrder.material_order_code(params[:store_id].to_i),
              :car_num_id => is_new_cus==0 ? customer.car_num_id : car_num.id,
              :status => Order::STATUS[:WAIT_PAYMENT],
              :price => card.price,
              :is_billing => false,
              :front_staff_id => params[:user_id],
              :customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
              :store_id => params[:store_id],
              :is_visited => Order::IS_VISITED[:NO],
              :types => Order::TYPES[:PRODUCT]
            })
          if pram_str[3].to_i == 0 ||  pram_str[3].to_i == 1   #如果是选的打折卡或储值卡，则要把这个卡加到该客户sv_cards中           
            if  pram_str[3].to_i == 0   #如果是打折卡
              CSvcRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
                :sv_card_id => card.id, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid])
              items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", card.id])
              arr = []
              items.each do |i|
                i_hash = {}
                i_hash[:pid] = i.id
                i_hash[:pname] = i.name
                i_hash[:pprice] = i.sale_price
                i_hash[:pdiscount] = i.product_discount.to_i*0.1
                i_hash[:selected] = 1
                arr << i_hash
              end
              sv_cards << {:svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
                :show_price => card.price, :products => arr}
            elsif pram_str[3].to_i ==1  #如果是储值卡
              money = card.svcard_prod_relations.first
              CSvcRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
                :sv_card_id => card.id, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid],
                :total_price => money.base_price+money.more_price, :left_price => money.base_price+money.more_price)
              item = SvcardProdRelation.where(["sv_card_id = ? ", card.id]).first
              arr = []
              item.category_id.split(",").each do |i|
                i_hash = {}
                i_hash[:pid] = i.to_i
                category = Category.find_by_id(i.to_i)
                i_hash[:pname] = category.nil? ? nil : category.name
                arr << i_hash
              end
              sv_cards << {:svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
                :show_price => card.price, :products => arr}
            end
          elsif pram_str[3].to_i == 2 #如果是选的套餐卡，则要把这个套餐卡加到该客户p_cards中
            pitems = PcardProdRelation.find_by_sql(["select ppr.product_num num, p.name name,p.id id, p.sale_price sale_price
             from pcard_prod_relations ppr inner join products p on ppr.product_id=p.id where ppr.package_card_id=?", card.id])
            pstr = ""
            b = []
            c = []
            pitems.each do |pi|
              b << "#{pi.id}-#{pi.name}-#{pi.num}"
              c << {:proid => pi.id, :proname => pi.name, :pro_left_count => pi.num, :selected => 1, :pprice => pi.sale_price}
            end
            pstr = b.join(",")
            ended_at = card.date_types==PackageCard::TIME_SELCTED[:PERIOD] ? card.ended_at : Time.now + card.date_month.to_i.days
            CPcardRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id, 
              :package_card_id => card.id, :ended_at => ended_at, :status => CPcardRelation::STATUS[:INVALID], :content => pstr,
              :price => card.price, :order_id => order.id)
            p_cards << {:pid => card.id, :pname => card.name, :pprice => card.price, :ptype => 2, :is_new => 1,
              :show_price => card.price, :products => c}
          end
        else
          status = 0
          msg = "没有找到所选择的卡!"
        end
      end

      #获取所有的车品牌/型号
      capital_arr = status==0 ? [] : Capital.get_all_brands_and_models

      order_infos = {
        :cid => is_new_cus==0 ? customer.customer_id : customer.id,
        :cname => is_new_cus==0 ? customer.name : nil,
        :csex => is_new_cus==0 ? customer.sex : 1,
        :cmoilephone => is_new_cus==0 ? customer.mobilephone : nil,
        :cproperty => customer.property.to_i,
        :cnum => params[:num],
        :cnum_id => is_new_cus==0 ? customer.car_num_id : car_num.id,
        :cmodel => is_new_cus==0 ? customer.model_name : nil,
        :cbrand => is_new_cus==0 ? customer.brand_name : nil,
        :cbirthday => is_new_cus==0 ? (customer.birth.nil? ? nil : customer.birth) : nil,
        :cbuyyear => is_new_cus==0 ? customer.year : nil,
        :cdistance => is_new_cus==0 ? customer.distance : nil,
        :oid => order.nil? ? nil : order.id,
        :ocode => order.nil? ? nil : order.code,
        :oprice => order.nil? ? nil : order.price,
        :opname => product.nil? ? (card.nil? ? nil : card.name) : product.name
      }
      p = []
      unless product.nil?
        p << {:id => product.id, :name => product.name, :count => pram_str[1].to_i,
          :price => product.sale_price, :show_price => product.sale_price* pram_str[1].to_i}
      end
      work_orders = working_orders params[:store_id]
      render :json => {:status => status, :order_infos => order_infos, :orders => work_orders, :msg => msg, :product => p, :sales => sales,
        :sv_cards => sv_cards, :p_cards => p_cards, :save_cards => save_cards.nil? ? [] : save_cards, :car_info => capital_arr}
    end
  end

  #快速下单
  def quickly_make_order
    status = 1
    msg = ""
    sid = params[:service_id].to_i
    num = params[:num]
    store_id = params[:store_id].to_i
    user_id = params[:user_id].to_i
    Customer.transaction do
      customer = CarNum.get_customer_info_by_carnum(store_id, num)
      is_new_cus = 0
      if customer.nil?
        #如果是新的车牌，则要创建一个空白的客户和车牌，以及客户-门店、客户-车牌关联记录
        customer = Customer.create(:status => Customer::STATUS[:NOMAL])
        car_num = CarNum.create(:num => num)
        customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
        relation = CustomerStoreRelation.find_by_store_id_and_customer_id(store_id, customer.id)
        customer.customer_store_relations.create({:customer_id => customer.id, :store_id => store_id}) unless relation
        customer.save
        is_new_cus = 1
      end
      create_result = OrderProdRelation.make_record(sid, 1, user_id,
        is_new_cus == 0 ? customer.customer_id : customer.id,  is_new_cus == 0 ? customer.car_num_id : car_num.id, store_id)
      status = create_result[0]
      msg = create_result[1]
      work_orders = working_orders store_id
      render :json => {:status => status, :msg => msg, :orders => work_orders}
    end
  end
  #同步pad上面的订单和客户信息
  def sync_orders_and_customer
    sync_info = JSON.parse(params[:syncInfo])
    orders = sync_info["order"]
    Order.transaction do
      orders.each do |o|
        status = o["status"].to_i #0取消订单，1已付款
        order = Order.find_by_id(o["order_id"].to_i)       
        if status==0    #0取消订单
          oprs = order.order_prod_relations
          oprs.each do |opr|    #如果有对应的物料，则要将这些物料对应的数量补上
            pid = opr.product_id
            pnum = opr.pro_num
            pmrs = ProdMatRelation.where(["product_id = ?", pid])
            pmrs.each do |pmr|
              mnum = pmr.material_num
              mid = pmr.material_id
              mater = Material.find_by_id(mid)
              mater.update_attribute("storage", mater.storage+(pnum * mnum))
            end if pmrs
          end if oprs
          order.update_attributes(:status  => Order::STATUS[:RETURN])          
        elsif status==1 #已付款
          customer = Customer.find_by_id(o["customer_id"].to_i)
          customer.update_attributes(:name => o["userName"].nil? ? nil : o["userName"].strip, :mobilephone => o["phone"].nil? ? nil : o["phone"].strip,
            :birthday => o["birth"].nil? ||o["birth"].strip=="" ? nil :o["birth"], :sex => o["sex"].to_i)
          car_num = CarNum.find_by_id(o["car_num_id"].to_i)
          car_num.update_attributes(:car_model_id => o["brand"].nil? || o["brand"].split("_")[1].nil? ? nil : o["brand"].split("_")[1].to_i,
            :buy_year => o["year"], :distance => o["cdistance"].nil? ? nil : o["cdistance"].to_i)
          if o["pay_type"].to_i == 0 #现金付款
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH], :price => o["total_price"].to_f)
          elsif o["pay_type"].to_i ==5 #免单
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType[:IS_FREE], :price => o["total_price"].to_f)
          end
          order.update_attributes(:status  => Order::STATUS[:BEEN_PAYMENT], :is_pleased => o["is_please"].to_i, :is_billing => o["billing"].to_i)
          if (o["reason"] && o["reason"].strip != "") || (o["request"] && o["request"].strip != "")
            Complaint.create(:order_id => order.id, :reason => o["reason"], :suggestion => o["request"],
              :status => Complaint::STATUS[:UNTREATED], :types => Complaint::TYPES[:OTHERS])
          end
          sale_id = []
          c_pcard_relation_id = []
          c_svc_relation_id = []
          prods = o["prods"].split(",") #[0_255_2_200, 1_47_255=20, 2_322_0_0_16=200_128, 3_111_0_16=2_147]
          prods.each do |prod|  #1_47_255=20
            if prod.split("_")[0].to_i==1 #如果有活动   [1,47,255=20]
              arr = prod.split("_")
              sale_id << arr[1].to_i  #[1,47,255=20]
              arr.each do |a|  #[1,47,255=20]
                if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                  OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE], :price => a.split("=")[1].to_f,
                    :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
                end
              end
            elsif prod.split("_")[0].to_i==2  #如果有优惠卡 2_322_0_0_16=200_128
              arr = prod.split("_")
              sid = arr[1].to_i
              if arr[2].to_i==0 #如果是打折卡
                arr.each do |a|
                  if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                    OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                      :price => a.split("=")[1].to_f, :product_id => a.split("=")[0].to_i, :production_num => a.split("=")[2].to_i)
                  end
                end
                if arr[3].to_i==0 #如果是用户已有的打折卡
                  csrid = arr[-1].to_i  #用户-打折卡关联id
                  c_svc_relation_id << csrid
                elsif arr[3].to_i==1  #如果是用户刚买的打折卡，则要简历客户-打折卡关系记录
                  csr = CSvcRelation.create(:customer_id => customer.id, :sv_card_id => sid, :is_billing => o["billing"].to_i,
                    :status => CSvcRelation::STATUS[:valid], :order_id => order.id)
                  c_svc_relation_id << csr.id
                end
              elsif  arr[2].to_i==1 && arr[3].to_i==1 #如果是新买的储值卡，则创建储值卡-用户关联关系
                save_c = SvCard.find_by_sql(["select s.id sid, s.name sname, spr.base_price bprice, spr.more_price mprice from sv_cards s
                inner join svcard_prod_relations spr on s.id=spr.sv_card_id where s.id=?", sid])[0]
                csr = CSvcRelation.create(:customer_id => customer.id, :sv_card_id => save_c.sid, :total_price => save_c.bprice.to_f + save_c.mprice.to_f,
                  :left_price => save_c.bprice.to_f + save_c.mprice.to_f, :is_billing => o["billing"].to_i, :order_id => order.id,
                  :status => CSvcRelation::STATUS[:valid], :password => Digest::MD5.hexdigest(arr[-1].strip))
                SvcardUseRecord.create(:c_svc_relation_id => csr.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,
                  :left_price => save_c.bprice.to_f + save_c.mprice.to_f, :content => "购买"+"#{save_c.sname}")
              end
            elsif prod.split("_")[0].to_i==3  #如果是套餐卡
              arr = prod.split("_")
              pid = arr[1].to_i
              selected_prods = arr.inject({}){|a, s|   #[2-5,56-1]
                if !s.split("=")[1].nil?
                  apid = s.split("=")[0].to_i
                  apcount = s.split("=")[1].to_i
                  a[apid] = apcount
                end;
                a
              }
              if arr[2].to_i==0 #如果是用户已有的套餐卡,则要扣除购买的产品对应的数量
                cprid = arr[-1].to_i
                cpr = CPcardRelation.find_by_id(cprid)
                cpr_content = cpr.content.split(",") #[2-产品1-22,56-服务2-3, 17-产品2-3]
                a = []
                (cpr_content ||[]).each do |cc|
                  ccid = cc.split("-")[0].to_i
                  ccname = cc.split("-")[1]
                  cccount = cc.split("-")[2].to_i
                  if selected_prods[ccid]
                    a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                  else
                    a << "#{ccid}-#{ccname}-#{cccount}"
                  end
                end
                cpr.update_attribute("content", a.join(","))
                c_pcard_relation_id << cpr.id
              else  #如果是用户刚买的套餐卡，则要扣掉刚买的产品，并且生成客户-套餐卡关系
                pc_items = PcardProdRelation.find_by_sql(["select p.id, p.name, ppr.product_num num from package_cards pc inner join pcard_prod_relations
             ppr on pc.id=ppr.package_card_id inner join products p on ppr.product_id=p.id where pc.id=?", pid])
                cpr_content = pc_items.inject([]){|a, p|a << "#{p.id}-#{p.name}-#{p.num}";a}  #[2-产品1-22,56-服务2-3, 17-产品2-3]
                a = []
                (cpr_content ||[]).each do |cc|
                  ccid = cc.split("-")[0].to_i
                  ccname = cc.split("-")[1]
                  cccount = cc.split("-")[2].to_i
                  if selected_prods[ccid]
                    a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                  else
                    a << "#{ccid}-#{ccname}-#{cccount}"
                  end
                end
                pcard = PackageCard.find_by_id(pid)
                if pcard.date_types == PackageCard::TIME_SELCTED[:END_TIME]  #根据套餐卡的类型设置截止时间
                  ended_at = (Time.now + (pcard.date_month).days).to_datetime
                else
                  ended_at = pcard.ended_at
                end
                cpr = CPcardRelation.create(:customer_id => customer.id, :package_card_id => pcard.id, :ended_at => ended_at,
                  :status => CPcardRelation::STATUS[:NORMAL], :content => a.join(","), :price => pcard.price, :order_id => order.id)
                c_pcard_relation_id << cpr.id
              end
              (selected_prods).each do |k, v|
                OPcardRelation.create(:order_id => order.id, :c_pcard_relation_id => cpr.id, :product_id => k, :product_num => v)
                product = Product.find_by_id(k)
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
                  :price => product.sale_price * v, :product_id => k, :product_num => v)
              end if selected_prods.length > 0
            end
          end if prods
        elsif status == 2    #未付款,只是客户不满意，提出投诉评论
          if (o["request"] || o["reason"]) && o["is_please"].to_i == 0
            Complaint.create(:order_id => order.id, :reason => o["reason"], :suggestion => o["request"],
              :status => Complaint::STATUS[:UNTREATED], :types => Complaint::TYPES[:OTHERS])
            order.update_attributes(:status => Order::STATUS[:WAIT_PAYMENT], :is_pleased => o["is_please"].to_i)
          end
        end
      end
      work_orders = working_orders sync_info["store_id"].to_i
      render :json => {:status => 1, :orders => work_orders}
    end
  end

  #以前的make_order接口
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
    msg = ""
    if params[:wo_station_ids]
      WorkOrder.transaction do
        wo_station_ids = params[:wo_station_ids].split(",")
        flag = 0
        wo_station_ids.each do |ws|
          wid,sid = ws.split("_")
          wo = WorkOrder.find_by_id(wid)
          station = Station.find_by_id(sid)
          if station.status != Station::STAT[:NORMAL]
            flag = 1
            status = 1
            msg = "#{station.name}异常，暂时无法服务!"
          else
            station_prods = StationServiceRelation.where(["station_id=?", station.id]).map(&:product_id) #获取要调换到的那个工位所支持的服务
            order = wo.order
            opr = order.order_prod_relations.map(&:product_id)
            serv_ids = Product.where(["is_service=? and id in (?)", Product::PROD_TYPES[:SERVICE], opr]).map(&:id)
            if station_prods.include?(serv_ids) == false
              flag = 1
              status = 1
              msg = "#{station.name}不支持该服务!"
            end
          end
        end
        if flag == 0
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
            order.update_attributes(:cons_staff_id_1 =>staff_id_1,:cons_staff_id_2 => staff_id_2, :station_id => wo.station_id) if order
          end
        end
      end
      work_orders = working_orders params[:store_id]
    else
      status = 1
    end
    render :json => {:status => status, :msg => msg, :orders => work_orders}
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
    status = 1
    msg = ""
    oid = params[:order_id].to_i
    store_id = params[:store_id].to_i
    Order.transaction do
      order = Order.find_by_id(oid)
      if order.status == Order::STATUS[:BEEN_PAYMENT]
        status = 0
        msg = "该订单已付款!"
        work_orders = working_orders store_id
        render :jsoin => {:status => status, :msg => msg, :orders => work_orders}
      else
        oprs = order.order_prod_relations
        opcsvc = CSvcRelation.find_by_order_id_and_status(order.id, CSvcRelation::STATUS[:invalid])
        opcpc = CPcardRelation.find_by_order_id_and_status(order.id, CPcardRelation::STATUS[:INVALID])
        customer = Customer.find_by_id(order.customer_id)
        car_num = CarNum.find_by_id(order.car_num_id)
        car_model = car_num.nil? || car_num.car_model_id.nil? ? nil : CarModel.find_by_id(car_num.car_model_id)
        car_brand = car_model.nil? || car_model.car_brand_id.nil? ? nil : CarBrand.find_by_id(car_model.car_brand_id)
        sv_cards = []
        p_cards = []
        save_cards = []
        sales = []
        opname = []
        p = []
        if oprs.any? #如果该订单购买的是产品或者服务
          #该用户所购买的打折卡及其所支持的产品或服务
          sv_cards = CSvcRelation.get_customer_discount_cards(customer.id,store_id)
          #该用户所购买的套餐卡及其所支持的产品或服务
          p_cards = CPcardRelation.get_customer_package_cards(customer.id, store_id)
          #该用户所购买的储值卡及其所支持的产品或服务类型
          oprs.each do |opr|
            sc = CSvcRelation.get_customer_supposed_save_cards(customer.id, store_id,opr.product_id)
            save_cards << sc
            product = Product.find_by_id(opr.product_id)
            unless product.nil?
              p << {:id => product.id, :name => product.name, :count => opr.pro_num,
                :price => product.sale_price, :show_price => product.sale_price* opr.pro_num}
            end
            #获取支持该产品的活动
            opname << product.name
            s = Order.get_sale_by_product(product, order.car_num_id) if product
            sales << s
          end
          sales = sales.flatten(1).uniq
          save_cards = save_cards.flatten.uniq
        elsif opcsvc  #如果购买的是储值卡或者打折卡
          card = SvCard.find_by_id(opcsvc.sv_card_id)
          if card && card.types == SvCard::FAVOR[:DISCOUNT]
            items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", card.id])
            a = []
            items.each do |i|
              hash = {}
              hash[:pid] = i.id
              hash[:pname] = i.name
              hash[:pprice] = i.sale_price
              hash[:pdiscount] = i.product_discount.to_i*0.1
              hash[:selected] = 1
              a << hash
            end
            sv_cards << {:csrid => opcsvc.id, :svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
              :show_price => card.price, :products => a}
          elsif  card && card.types == SvCard::FAVOR[:SAVE]
            item = SvcardProdRelation.where(["sv_card_id = ? ", card.id]).first
            arr = []
            item.category_id.split(",").each do |i|
              i_hash = {}
              i_hash[:pid] = i.to_i
              category = Category.find_by_id(i.to_i)
              i_hash[:pname] = category.nil? ? nil : category.name
              arr << i_hash
            end
            sv_cards << {:svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
              :show_price => card.price, :products => arr}
          end
        elsif opcpc
          card = PackageCard.find_by_id(opcpc.package_card_id)
          pitems = PcardProdRelation.find_by_sql(["select ppr.product_num num, p.name name,p.id id, p.sale_price sale_price
             from pcard_prod_relations ppr inner join products p on ppr.product_id=p.id where ppr.package_card_id=?", card.id])
          c = []
          pitems.each do |pi|              
            c << {:proid => pi.id, :proname => pi.name, :pro_left_count => pi.num, :selected => 1, :pprice => pi.sale_price}
          end
          p_cards << {:pid => card.id, :pname => card.name, :pprice => card.price, :ptype => 2, :is_new => 1,
            :show_price => card.price, :products => c}
        end
        #获取所有的车品牌/型号
        capital_arr = Capital.get_all_brands_and_models
        order_infos = {
          :cid => customer.id,
          :cname =>customer.name,
          :csex => customer.sex,
          :cmoilephone =>customer.mobilephone,
          :cnum => car_num.num,
          :cnum_id => car_num.id,
          :cmodel => car_model.nil? ? nil : car_model.name,
          :cbrand => car_brand.nil? ? nil : car_brand.name,
          :cbirthday => customer.birthday.nil? ? nil : customer.birthday.strftime("%Y-%m-%d"),
          :cbuyyear => car_num.nil? ? nil : car_num.buy_year,
          :cdistance => car_num.nil? ? nil : car_num.distance,
          :oid => order.nil? ? nil : order.id,
          :ocode => order.nil? ? nil : order.code,
          :oprice => order.nil? ? nil : order.price,
          :oplease => order.nil? ? nil : order.is_pleased,
          :opname => opname.join(",")
        }
        render :json => {:status => status, :msg => msg, :order_infos => order_infos,  :product => p,
          :sales => sales, :sv_cards => sv_cards, :p_cards => p_cards, :save_cards => save_cards, :car_info => capital_arr}
      end
    end
  end

  #付款
  def pay_order
    #prods参数格式: 产品：0_id_count_price 0开头，id，数量，价格总价
    #活动: 1_id_id=price  1开头，活动的id,活动使用的产品(服务)id=活动优惠的价格
    #储值卡 2_id_type_is_new_id_password  2开头，储值卡id，类型(1)，是否是新的，密码
    #打折卡 2_id_type_is_new_id=price_cid 2开头，打折卡id，类型(0)，是否是新的，打折卡打折的产品(服务)id=打折的价格，客户-打折卡关联的id
    #套餐卡 3_id_is_new_id=price_cid    3开头，套餐卡id,是否是新的，套餐卡使用的产品(服务)id=使用的次数，客户-套餐卡关联的id
    #brand: 1_2 brand的id_model的id, userName 客户的name
    Customer.transaction do
      customer = Customer.find_by_id(params[:customer_id].to_i)
      car_num = CarNum.find_by_id(params[:car_num_id].to_i)
      car_num.update_attributes(:car_model_id => params[:brand].nil? || params[:brand].split("_")[1].nil? ? nil : params[:brand].split("_")[1].to_i,
        :buy_year => params[:year], :distance => params[:distance].nil? ? nil : params[:distance].to_i)
      if customer.mobilephone != params[:phone] #如果输入的电话号码不是该客户的电话号码
        customer2 = Customer.find_by_mobilephone_and_status(params[:phone], Customer::STATUS[:NOMAL])
        if customer2.nil? #如果该电话号码没有被用过,则更新该客户信息
          customer.update_attributes(:name => params[:userName].nil? ? nil : params[:userName].strip, :mobilephone => params[:phone].nil? ? nil : params[:phone].strip,
            :birthday => params[:birth].nil? || params[:birth].strip=="" ? nil : params[:birth].strip.to_datetime, :sex => params[:sex].to_i)
        else  #如果该电话号码已被用，则查出这个客户，并且把这个车牌关联到这个客户下，并且删除原来的客户
          customer2.update_attributes(:name => params[:userName].nil? ? nil : params[:userName].strip,
            :birthday => params[:birth].nil? || params[:birth].strip=="" ? nil : params[:birth].strip.to_datetime, :sex => params[:sex].to_i)
          cnr2 = CustomerNumRelation.find_by_customer_id_and_car_num_id(customer2.id, car_num.id)
          if cnr2.nil?
            CustomerNumRelation.create(:customer_id => customer2.id, :car_num_id => car_num.id)
          end
          CustomerNumRelation.delete_all(:customer_id => customer.id, :car_num_id => car_num.id)
          customer.destroy
          customer = customer2
        end
      else
        customer.update_attributes(:name => params[:userName].nil? ? nil : params[:userName].strip,
          :birthday => params[:birth].nil? || params[:birth].strip=="" ? nil : params[:birth].strip.to_datetime, :sex => params[:sex].to_i)
      end
      order = Order.find_by_id(params[:order_id].to_i)
      order.update_attribute("customer_id", customer.id)
      total_price = params[:total_price].to_f
      is_billing = params[:billing].to_i
      pay_type = params[:pay_type].to_i
      is_pleased = params[:is_please].to_i
      status = 1
      msg = "付款成功!"
      if pay_type == 0 #现金
        OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH], :price => total_price)
      elsif pay_type==1 #储值卡
        customer_savecard = CSvcRelation.find_by_id(params[:csrid].to_i)
        if customer_savecard
          if customer_savecard.password==Digest::MD5.hexdigest(params[:password].strip)
            if customer_savecard.left_price > total_price
              SvcardUseRecord.create(:c_svc_relation_id => customer_savecard.id, :types => SvcardUseRecord::TYPES[:OUT],
                :use_price => total_price, :left_price => customer_savecard.left_price - total_price)
              customer_savecard.update_attribute("left_price", customer_savecard.left_price - total_price)
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SV_CARD], :price => total_price)
            else
              status = 0
            end
          else
            status = 0
            msg = "密码错误!"
          end
        else
          status = 0
          msg = "数据错误!"
        end
      elsif pay_type==5 #免单
        OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:IS_FREE], :price => total_price)
      end
      if status==1
        c_pcard_relation_id = []
        c_svc_relation_id = []
        deduct_price = 0
        techin_price = 0
        sale_id = 0
        prods = params[:prods].split(",") #[0_255_2_200, 1_47_255=20, 2_322_0_0_16=200_128, 3_111_0_16=2_147]
        prods.each do |prod|  #1_47_255=20
          if prod.split("_")[0].to_i==0 #如果有产品
            arr = prod.split("_")
            product = Product.find_by_id(arr[1].to_i)
            deduct_price = deduct_price + (product.deduct_price+product.deduct_percent) * arr[2].to_i
            techin_price = techin_price + (product.techin_price+product.techin_percent) * arr[2].to_i
          elsif prod.split("_")[0].to_i==1 #如果有活动   [1,47,255=20]
            arr = prod.split("_")
            sale_id = arr[1].to_i  #[1,47,255=20]
            arr.each do |a|  #[1,47,255=20]
              if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE], :price => a.split("=")[1].to_f,
                  :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
              end
            end
          elsif prod.split("_")[0].to_i==2  #如果有优惠卡 2_322_0_0_16=200_128
            arr = prod.split("_")
            sid = arr[1].to_i
            if arr[2].to_i==0 #如果是打折卡
              arr.each do |a|
                if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                  OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                    :price => a.split("=")[1].to_f, :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
                end
              end
              if arr[3].to_i==0 #如果是用户已有的打折卡
                csrid = arr[-1].to_i  #用户-打折卡关联id
                c_svc_relation_id << csrid
              elsif arr[3].to_i==1  #如果是用户刚买的打折卡，则要更新客户-打折卡关系记录
                csr = CSvcRelation.where(["customer_id=? and sv_card_id=? and order_id=? and status=?", customer.id,
                    sid, order.id, CSvcRelation::STATUS[:invalid]]).first
                if csr.nil?
                  status = 0
                  msg = "数据错误!"
                else
                  csr.update_attributes(:status => CSvcRelation::STATUS[:valid], :is_billing => is_billing)
                  c_svc_relation_id << csr.id
                end
              end
            elsif  arr[2].to_i==1 && arr[3].to_i==1 #如果是新买的储值卡，则更新储值卡-用户关联关系
              save_c = SvCard.find_by_id(sid)
              csr = CSvcRelation.where(["customer_id=? and sv_card_id=? and order_id=? and status=?", customer.id, sid,
                  order.id, CSvcRelation::STATUS[:invalid]]).first
              if csr.nil?
                status = 0
                msg = "数据错误!"
              else
                csr.update_attributes(:status => CSvcRelation::STATUS[:valid], :is_billing => is_billing,
                  :password => Digest::MD5.hexdigest(arr[-1].strip))
                SvcardUseRecord.create(:c_svc_relation_id => csr.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,
                  :left_price => csr.left_price, :content => "购买"+"#{save_c.name}")
              end
            end
          elsif prod.split("_")[0].to_i==3  #如果是套餐卡
            arr = prod.split("_")
            pid = arr[1].to_i
            selected_prods = arr.inject({}){|a, s|   #[2-5,56-1]
              if !s.split("=")[1].nil?
                apid = s.split("=")[0].to_i
                apcount = s.split("=")[1].to_i
                a[apid] = apcount
              end;
              a
            }
            if arr[2].to_i==0 #如果是用户已有的套餐卡,则要扣除购买的产品对应的数量
              cprid = arr[-1].to_i
              cpr = CPcardRelation.find_by_id(cprid)
              cpr_content = cpr.content.split(",") #[2-产品1-22,56-服务2-3, 17-产品2-3]
              a = []
              (cpr_content ||[]).each do |cc|
                ccid = cc.split("-")[0].to_i
                ccname = cc.split("-")[1]
                cccount = cc.split("-")[2].to_i
                if selected_prods[ccid]
                  a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                else
                  a << "#{ccid}-#{ccname}-#{cccount}"
                end
              end
              cpr.update_attribute("content", a.join(","))
              c_pcard_relation_id << cpr.id
            elsif arr[2].to_i==1  #如果是用户刚买的套餐卡，则要扣掉刚买的产品，并且生成客户-套餐卡关系
              pcard = PackageCard.find_by_id(pid)
              deduct_price = deduct_price + (pcard.deduct_price+pcard.deduct_percent)
              cpr = CPcardRelation.where(["customer_id=? and package_card_id=? and status=? and order_id=?", customer.id,
                  pid, CPcardRelation::STATUS[:INVALID], order.id]).first
              cpr_content = cpr.content.split(",")
              a = []
              (cpr_content ||[]).each do |cc|
                ccid = cc.split("-")[0].to_i
                ccname = cc.split("-")[1]
                cccount = cc.split("-")[2].to_i
                if selected_prods[ccid]
                  a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                else
                  a << "#{ccid}-#{ccname}-#{cccount}"
                end
              end
              cpr.update_attributes(:status => CPcardRelation::STATUS[:NORMAL], :content => a.join(","))
            end
            (selected_prods).each do |k, v|
              OPcardRelation.create(:order_id => order.id, :c_pcard_relation_id => cpr.id, :product_id => k, :product_num => v)
              product = Product.find_by_id(k)
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
                :price => product.sale_price * v, :product_id => k, :product_num => v)
            end if selected_prods.length > 0
          end
        end if prods
        order.update_attributes(:is_pleased => is_pleased, :is_billing => is_billing, :is_free => pay_type==5 ? 1 : 0,
          :sale_id => sale_id.nil? || sale_id == 0 ? nil : sale_id, :c_pcard_relation_id => c_pcard_relation_id.blank? ? nil : c_pcard_relation_id.join(","),
          :c_svc_relation_id => c_svc_relation_id.blank? ? nil : c_svc_relation_id.join(","), :status => Order::STATUS[:BEEN_PAYMENT],
          :front_deduct => deduct_price, :technician_deduct => techin_price * 0.5)
        work_order = WorkOrder.find_by_order_id(order.id)
        if work_order
          work_order.update_attribute("status", WorkOrder::STAT[:COMPLETE])
        end
      end
      work_orders = status==0 ? nil : working_orders(params[:store_id])
      render :json => {:status => status, :msg => msg, :orders => work_orders}
    end
  end

  #取消订单
  def cancel_order
    Order.transaction do
      order = Order.find_by_id(params[:order_id].to_i)
      #      opr = order.order_prod_relations
      #      opr.each do |o|
      #        pid = o.product_id
      #        pnum = o.pro_num
      #        pmrs = ProdMatRelation.where(["product_id = ?", pid])
      #        pmrs.each do |pmr|
      #          mnum = pmr.material_num
      #          mid = pmr.material_id
      #          mater = Material.find_by_id(mid)
      #          mater.update_attribute("storage", mater.storage+(pnum * mnum))
      #        end
      #      end if opr
      if order.update_attribute("status", Order::STATUS[:DELETED])
        order.work_orders.inject([]){|h,wo| wo.update_attribute("status", WorkOrder::STAT[:CANCELED])}
        work_orders = working_orders params[:store_id]
        render :json => {:status => 1, :msg => "退单成功!", :orders => work_orders}
      end
    end
  end
  
  #生成订单投诉记录
  def complaint
    complaint = Complaint.mk_record(params[:store_id],params[:order_id],params[:reason],params[:request],0)
    render :json => {:status => (complaint.nil? ? 0 : 1)}
  end

  def working_orders(store_id)
    orders = Order.working_orders store_id.to_i
    orders = combin_orders(orders)
    orders = new_app_order_by_status(orders)
    orders
  end
end