#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
  has_many :svcard_use_records
  belongs_to :sv_card
  has_one :order
  belongs_to :customer

  STATUS = {:valid => 1, :invalid => 0}         #1有效的，0无效
  SEL_METHODS = {:PCARD => 2,:SV =>1,:DIS =>0 ,:BY_PCARD => 3, :BY_SV => 4,:PROD =>6,:SERV =>5}
  #1 购买储值卡 0  购买打折卡 2 购买套餐卡 3 通过套餐卡购买 4 通过打折卡购买 5 购买服务 6 购买产品
  SEL_PROD = [SEL_METHODS[:BY_PCARD],SEL_METHODS[:BY_SV],SEL_METHODS[:PROD],SEL_METHODS[:SERV]]
  SEL_SV = [SEL_METHODS[:SV],SEL_METHODS[:DIS]]

  #获取用户的已购买的所有打折卡
  def self.get_customer_discount_cards  customer_id, store_id
    sc = CSvcRelation.find_by_sql(["select sv.id sid, sv.name sname, sv.types stype, sv.price sprice, csr.id csrid from c_svc_relations csr inner join
          sv_cards sv on sv.id=csr.sv_card_id where csr.customer_id=? and csr.status=? and ((sv.store_id=? and sv.use_range=?)or(sv.store_id in (?) and
          sv.use_range=?)) and sv.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::FAVOR[:DISCOUNT]]).uniq
    sv_cards = sc.inject([]){|h,s|
      a = {}
      a[:csrid] = s.csrid
      a[:svid] = s.sid
      a[:svname] = s.sname
      a[:svprice] = s.sprice
      a[:svtype] = s.stype
      a[:is_new] = 0
      a[:show_price] = 0
      a[:products] = []
      items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", s.sid])
      items.each do |i|
        hash = {}
        hash[:pid] = i.id
        hash[:pname] = i.name
        hash[:pprice] = i.sale_price
        hash[:pdiscount] = i.product_discount.to_i*0.1
        hash[:selected] = 1
        a[:products] << hash
      end
      h << a;
      h
    }
    sv_cards
  end

  #获取该用户所有支持某个产品付款的储值卡
  def self.get_customer_supposed_save_cards  customer_id, store_id, p_id
    result = []
    sc = CSvcRelation.find_by_sql(["select csr.id csrid, csr.left_price l_price, sc.id sid, sc.name sname
       from c_svc_relations csr inner join sv_cards sc on csr.sv_card_id=sc.id
      where csr.customer_id=? and csr.status=? and ((sc.store_id=? and sc.use_range=?)or(sc.store_id in (?) and
      sc.use_range=?)) and sc.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::FAVOR[:SAVE]]).uniq
    category_id = Product.find_by_id(p_id).category_id.to_i
    sc.each do |s|
      spr = SvcardProdRelation.find_by_sv_card_id(s.sid)
      if spr.category_id && spr.category_id.split(",").inject([]){|h, c| h << c.to_i;h }.include?(category_id)
        h = {}
        h[:csrid] = s.csrid
        h[:l_price] = s.l_price
        h[:svid] = s.sid
        h[:svname] = s.sname
        result << h
      end
    end
    return result
  end


  def self.search_card(customer_id,store_id)
    suit_cards,prods,pcard = [],[],[]
    cps = CPcardRelation.find_by_sql("select p.name,c.id c_id,c.content from c_pcard_relations c inner join package_cards p
      on c.package_card_id=p.id where customer_id=#{customer_id} and c.status=#{CPcardRelation::STATUS[:NORMAL]} and
      p.store_id = #{store_id} and date_format(c.ended_at,'%Y-%m-%d') >= '#{Time.now.strftime('%Y-%m-%d')}'")
    cps.each do |cp|
      if cp.content
        cp.content.split(",").each do |p|
          content = p.split("-")
          if content[2].to_i >0
            prods << content[0].to_i
          end
        end
      end
    end unless cps.blank?
    prod = Product.where(:id=>prods.flatten.compact.uniq).inject({}){|h,p|h[p.id]=p.sale_price.nil? ? 0 : p.sale_price ;h}
    total_prms = ProdMatRelation.joins(:material).where(:product_id=>prods).select("ifnull(FLOOR(materials.storage/material_num),0) num,product_id,material_id").group_by{|i|i.product_id}
    cps.each do |cp|
      is_null,con = false,[]
      cp.content.split(",").each do |p|
        content = p.split("-")
        if content[2].to_i >0
          if total_prms[content[0].to_i]
            available_num = []
            available = true
            total_prms[content[0].to_i].each do |prm|
              if prm.num <= 0
                available = false
                break
              end
              available_num << prm.num
            end
            if available
              is_null = true
              content[2] =  available_num.min if content[2].to_i > available_num.min
              con << content
            end
          elsif prod[content[0].to_i]
            is_null = true
            con << content
          end
        end
      end  if cp.content
      if is_null
        pcard << {:name =>cp.name,:content =>con,:c_id =>cp.c_id,:types =>3,:type_name =>"套餐卡"}
      end
    end unless cps.blank?
    cr_ids = CSvcRelation.where(:status=>CSvcRelation::STATUS[:valid],:customer_id=>customer_id).map(&:sv_card_id)
    unless cr_ids.blank?
      sv_names = SvCard.where(:id=>cr_ids,:types=>SvCard::FAVOR[:DISCOUNT],:store_id=>store_id).inject({}){|h,s|h[s.id]=s.name;h}
      sv_prod = SvcardProdRelation.joins(:product).where(:sv_card_id=>sv_names.keys).select("sv_card_id,product_id,product_discount,products.name").inject({}){|h,s|
        h[s.sv_card_id].nil? ? h[s.sv_card_id]={s.product_id=>[s.product_discount,s.name]} :h[s.sv_card_id][s.product_id]=[s.product_discount,s.name];h}
      sv_prod_ids = sv_prod.values.inject([]){|arr,h_s| arr << h_s.keys}
      prod.merge!(Product.find((sv_prod_ids).flatten.compact.uniq).inject({}){|h,p|h[p.id]=p.sale_price;h})
      total_prms = ProdMatRelation.joins(:material).where(:product_id=>sv_prod_ids).select("ifnull(FLOOR(materials.storage/material_num),0) num,product_id,material_id").group_by{|i|i.product_id}
      sv_names.each do |k,v|
        #筛选掉打折卡里面没有库存的产品或者服务
        suit_sv = {}
        sv_prod[k].each do |p,sv|
          if total_prms[p]
            available_num = []
            available = true
            total_prms[p].each do |prm|
              if prm.num <= 0
                available = false
                break
              end
              available_num << prm.num
            end
            suit_sv[p] = sv << available_num.min    if available
          end
        end
        unless suit_sv.empty?
          suit_cards << {:name =>v,:c_id =>k,:content =>suit_sv,:types =>4,:type_name =>"打折卡"}
        end
      end unless sv_names.empty?
    end
    [suit_cards,prod,pcard]
  end

  def self.set_string(len,str)
    return "0"*(len-"#{str}".length)+"#{str}"
  end

  def self.create_item(total_info,ids,customer,car_num,user_id,store_id)

    order_parm = {:car_num_id => car_num.id,:is_billing => false,:front_staff_id =>user_id,
      :customer_id=>customer.id,:store_id=>store_id,:is_visited => Order::IS_VISITED[:NO]
    }
    sv_cards,c_svc_relation,msg,order_pay_type,message_arr,redirect ={},[],[],[],[],true
    if ids[1]
      sv_cards = SvCard.where(:store_id=>store_id,:id=>ids[1]).inject({}){|h,s|h[s.id]=s;h}
      sv_price = SvcardProdRelation.where(:sv_card_id=>ids[1]).select("ifnull(sum(base_price+more_price),0) price,sv_card_id s_id").group("s_id").inject({}){|h,p|h[p.s_id]=p.price;h}
    end
    if  total_info[SEL_METHODS[:SV]]
      send_message = "#{customer.name}：您好，您购买的储值卡"
      total_info[SEL_METHODS[:SV]].each do |sv,num|
        s = sv.split("_")
        order = Order.create(order_parm.merge({:code => MaterialOrder.material_order_code(store_id),:types => Order::TYPES[:SAVE],
              :price=>sv_cards[s[2].to_i].price,:status => Order::STATUS[:WAIT_PAYMENT]}))
        c_svc_relation <<  CSvcRelation.new(:customer_id =>customer.id,:sv_card_id =>s[2].to_i, :order_id => order.id,
          :status => CSvcRelation::STATUS[:invalid],:total_price =>sv_price[s[2].to_i],  :left_price =>sv_price[s[2].to_i],
          :id_card=>set_string(5,CSvcRelation.joins(:customer).where(:"customers.store_id"=>store_id).count),:password=>Digest::MD5.hexdigest("#{customer.mobilephone[-6..-1]}"))
        message_arr << "#{sv_cards[s[2].to_i].name},余额为#{sv_price[s[2].to_i]}"
      end
      send_message += message_arr.join("、")+"，密码是#{customer.mobilephone[-6..-1]}，请您尽快付款使用。"
      message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{customer.mobilephone.strip}&Content=#{URI.escape(send_message)}&Exno=0"
      Product.create_message_http(Constant::MESSAGE_URL, message_route)
    end
    if total_info[SEL_METHODS[:DIS]]
      total_info[SEL_METHODS[:DIS]].each do |dis,num|
        d = dis.split("_")
        order = Order.create(order_parm.merge({:code => MaterialOrder.material_order_code(store_id),:types => Order::TYPES[:DISCOUNT],
              :price=>sv_cards[d[2].to_i].price,:status => Order::STATUS[:WAIT_PAYMENT]}))
        c_svc_relation <<  CSvcRelation.new(:customer_id=>customer.id,:sv_card_id =>d[2].to_i, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid])
      end
    end

    if  total_info[SEL_METHODS[:PCARD]]
      pcard = PackageCard.where(:store_id=>store_id,:id=>ids[2]).inject({}){|h,s|h[s.id]=s;h}
      card_content = PcardProdRelation.find_by_sql("select package_card_id p_id,group_concat(p.id,'-',p.name,'-',ppr.product_num) content from
         pcard_prod_relations ppr  inner join products p on ppr.product_id=p.id where ppr.package_card_id in (#{pcard.keys.join(',')})
         group by package_card_id").inject({}){|h,p|h[p.p_id]=p.content;h}
      #这个库存判断 因为是一个物料
      pmrs = PcardMaterialRelation.joins(:material).select("package_card_id p_id,material_id m_id,storage-material_num result").
        where(:package_card_id =>pcard.keys).group("package_card_id").inject({}){|h,p|h[p.p_id]=[p.result,p.m_id];h}
      total_info[SEL_METHODS[:PCARD]].each do |p_card,num|
        c = p_card.split("_")
        card = pcard[c[2].to_i]
        #如果套餐卡未绑定物料 或者 剩余库存大于0 且有内容的才可以购买
        if pmrs[card.id].nil? || ((pmrs[card.id] && pmrs[card.id][0] >= 0) && card_content[card.id])
          time = card.is_auto_revist ? Time.now + card.auto_time.to_i.hours : nil
          order = Order.create(order_parm.merge({:code => MaterialOrder.material_order_code(store_id),:types => Order::TYPES[:SAVE],:auto_time =>time ,:status => Order::STATUS[:WAIT_PAYMENT],
                :warn_time => card.auto_warn ? Time.now + card.time_warn.to_i.days : nil,:price=>card.price}))
          ended_at = card.date_types==PackageCard::TIME_SELCTED[:PERIOD] ? card.ended_at : Time.now + card.date_month.to_i.days
          CPcardRelation.create(:customer_id =>customer.id,:package_card_id => card.id, :ended_at => ended_at.strftime("%Y-%m-%d")+" 23:59:59",:price => card.price,
            :status => CPcardRelation::STATUS[:INVALID], :content => card_content[card.id], :order_id => order.id)
          if pmrs[card.id]
            material = Material.find_by_id(pmrs[card.id][1])
            material.update_attribute("storage",pmrs[card.id][0])
          end
        else
          msg << "#{card.name} 库存不足！"
          redirect = false
        end
      end
    end

    if  total_info[SEL_METHODS[:BY_PCARD]]
      total_info[SEL_METHODS[:BY_PCARD]].each do |prod,num|
        p = prod.split("_")
        result = OrderProdRelation.make_record(p[2].to_i,num.to_i,user_id,customer.id,car_num.id,store_id)
        unless result[1] == ""
          msg <<  result[1]
          redirect = false
        end
        if result[0] == 1
          cpr = CPcardRelation.where(:id=>p[0],:status =>CPcardRelation::STATUS[:NORMAL],:customer_id=>customer.id).first
          cpr_content = cpr.content.split(",") #[2-产品1-22,56-服务2-3, 17-产品2-3]
          acontent = []
          yes = true
          (cpr_content ||[]).each do |cc|
            ccid = cc.split("-")[0].to_i
            ccname = cc.split("-")[1]
            cccount = cc.split("-")[2].to_i
            if num && ccid == p[2].to_i
              acontent << "#{ccid}-#{ccname}-#{cccount - num}"
              yes = false if cccount > num
            else
              acontent << "#{ccid}-#{ccname}-#{cccount}"
              yes = false if cccount >0
            end
          end
          deduct = (result[2].deduct_price.nil? ? 0 : result[2].deduct_price) +(result[2].deduct_percent.nil? ? 0 : result[2].deduct_percent)
          t_deduct = result[2].techin_price+result[2].techin_percent
          update_status = {:content=>acontent.join(",")}
          update_status.merge(:status=>CPcardRelation::STATUS[:NOTIME]) if yes
          cpr.update_attributes(update_status)
          msg <<  result[1] unless result[1] == ""
          result[3].update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT],:front_deduct=>deduct,:technician_deduct=>t_deduct, :c_pcard_relation_id => cpr.id)
          tech_orders =  result[3].tech_orders
          tech_orders.update_all(:own_deduct =>t_deduct/tech_orders.length ) unless tech_orders.blank?
          OPcardRelation.create(:order_id => result[3].id, :c_pcard_relation_id => cpr.id, :product_id => p[2].to_i, :product_num => num)
          package_card = PackageCard.find(cpr.package_card_id)
          product = Product.find p[2].to_i
          if  package_card && package_card.sale_percent && product.sale_price #如果数据有误  将不生成优惠金额 只生成套餐卡付款方式
            pay_price = product.sale_price * num * package_card.sale_percent.round(2)
            sale_price= (product.sale_price * num) - pay_price
            order_pay_type << OrderPayType.new(:order_id => result[3].id, :pay_type => OrderPayType::PAY_TYPES[:FAVOUR], :price => sale_price.to_f,
              :product_id => p[2].to_i, :product_num => num)
          end
          order_pay_type << OrderPayType.new(:order_id =>result[3].id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD], :price => pay_price.nil? ? 0 : pay_price.to_f,
            :product_id => p[2].to_i, :product_num => num)
         
        end
      end
    end
    if  total_info[SEL_METHODS[:BY_SV]]
      total_info[SEL_METHODS[:BY_SV]].each do |sv,num|
        v = sv.split("_")
        discount = SvcardProdRelation.where(:product_id =>v[2].to_i,:sv_card_id =>v[0].to_i).first.product_discount
        result = OrderProdRelation.make_record(v[2].to_i,num.to_i,user_id,customer.id,car_num.id,store_id)
        if result[3]
          order_pay_type <<  OrderPayType.new(:order_id => result[3].id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
            :price =>result[2].sale_price*num.to_i*(100-discount)/100.0, :product_id =>v[2].to_i, :product_num =>num)
        end
        unless result[1] == ""
          msg <<  result[1] 
          redirect = false
        end
      end
    end
    info = [msg,redirect]
    info = prod_serv(total_info[SEL_METHODS[:PROD]],user_id,customer.id,car_num.id,store_id,info)
    info = prod_serv(total_info[SEL_METHODS[:SERV]],user_id,customer.id,car_num.id,store_id,info)
    OrderPayType.import order_pay_type unless order_pay_type.blank?
    CSvcRelation.import  c_svc_relation unless c_svc_relation.blank?
    info
  end

  def self.prod_serv(items,user_id,customer_id,car_num_id,store_id,info)
    if items
      items.each do |item,num|
        p = item.split("_")
        result = OrderProdRelation.make_record(p[2].to_i,num.to_i,user_id,customer_id,car_num_id,store_id)
        unless result[1] == ""
          info[0] <<  result[1]
          info[1] = false
        end
        if result[3] && result[2]
          sales = Sale.joins(:sale_prod_relations).where(:"sales.store_id"=>store_id,:"sale_prod_relations.product_id"=>result[2].id).
            where("sale_prod_relations.prod_num <= #{num} and sales.status =#{Sale::STATUS[:RELEASE]}").select("sales.*,sale_prod_relations.prod_num")
          unless sales.blank?
            suit_sale = {}
            sales.each do |sale|
              flag = 0
              if sale.disc_time_types==Sale::DISC_TIME[:TIME] && !sale.ended_at.nil? &&
                  sale.ended_at.strftime("%Y-%m-%d") < Time.now.strftime("%Y-%m-%d") #如果该活动的时间已经过了，则忽略
                flag = 1
              else
                sql = "car_num_id != #{car_num_id}"
                sql1 = "car_num_id = #{car_num_id}"
                if sale.disc_time_types == Sale::DISC_TIME[:DAY]
                  sql += " and date_format(created_at,'%Y-%m-%d')=#{Time.now.strftime('%Y-%m-%d')}"
                  sql1 += " and date_format(created_at,'%Y-%m-%d')=#{Time.now.strftime('%Y-%m-%d')}"
                elsif sale.disc_time_types == Sale::DISC_TIME[:MONTH]
                  sql += " and date_format(created_at,'%Y-%m')=#{Time.now.strftime('%Y-%m')}"
                  sql1 += " and date_format(created_at,'%Y-%m')=#{Time.now.strftime('%Y-%m')}"
                elsif sale.disc_time_types == Sale::DISC_TIME[:YEAR]
                  sql += " and date_format(created_at,'%Y')=#{Time.now.strftime('%Y')}"
                  sql1 += " and date_format(created_at,'%Y')=#{Time.now.strftime('%Y')}"
                elsif sale.disc_time_types == Sale::DISC_TIME[:WEEK]
                  sql += "  and YEARWEEK(date_format(created_at,'%Y-%m-%d')) = YEARWEEK(now())"
                  sql1 += " and YEARWEEK(date_format(created_at,'%Y-%m-%d')) = YEARWEEK(now())"
                end
                #活动关联的车辆信息
                order_sales = Order.where(:status=>Order::STATUS[:BEEN_PAYMENT],:sale_id=>sale.id).where(sql).group("car_num_id").length
                #当前车辆关联的活动信息
                car_sales  = Order.where(:status=>Order::STATUS[:BEEN_PAYMENT],:sale_id=>sale.id).where(sql1).count[0]
                if order_sales >= sale.car_num
                  flag = 1
                elsif car_sales >= sale.everycar_times
                  flag = 1
                end
              end
              if flag == 0
                if sale.disc_types == Sale::DISC_TYPES[:FEE]
                  suit_sale[sale.discount] = sale.id
                else
                  suit_sale[((10-sale.discount)*result[2].sale_price*num.to_i/10).round(2)] = sale.id
                end
              end
            end
            sale_price = suit_sale.sort[-1]
            if sale_price
              OrderPayType.create(:order_id => result[3].id, :pay_type => OrderPayType::PAY_TYPES[:SALE],
                :price =>sale_price[0], :product_id =>result[2], :product_num =>num)
              result[3].update_attribute(:sale_id,sale_price[1])
              info[0] << "已匹配活动: #{Sale.find(sale_price[1]).name}"
            end
          end
        end
      end
    end
    info
  end


end
