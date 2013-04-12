#encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_prod_relations
  has_many :order_pay_types
  has_many :work_orders
  belongs_to :car_num
  belongs_to :c_pcard_relation
  belongs_to :c_svc_relation
  belongs_to :customer
  belongs_to :sale
  has_many :revisit_order_relations

  IS_VISITED = {:YES => 1, :NO => 0} #1 已访问  0 未访问
  STATUS = {:NORMAL => 0, :SERVICING => 1, :WAIT_PAYMENT => 2, :BEEN_PAYMENT => 3, :FINISHED => 4, :DELETED => 5, :INNORMAL => 6}
  #0 正常未进行  1 服务中  2 等待付款  3 已经付款  4 已结束  5已删除  6未分配工位
  IS_FREE = {:YES=>1,:NO=>0} # 1免单 0 不免单
  TYPES = {:SERVICE => 0, :PRODUCT => 1} #0 服务  1 产品
  FREE_TYPE = {:ORDER_FREE =>"免单",:PCARD =>"套餐卡使用"}
  #是否满意
  IS_PLEASED = {:BAD => 0, :SOSO => 1, :GOOD => 2, :VERY_GOOD => 3}  #0 不满意  1 一般  2 好  3 很好
  IS_PLEASED_NAME = {0 => "不满意", 1 => "一般", 2 => "好", 3 => "很好"}

  #组装查询order的sql语句
  def self.generate_order_sql(started_at, ended_at, is_visited)
    condition_sql = ""
    params_arr = [""]
    unless started_at.nil? or started_at.strip.empty?
      condition_sql += " and o.created_at >= ? "
      params_arr << started_at.strip
    end
    unless ended_at.nil? or ended_at.strip.empty?
      condition_sql += " and o.created_at <= ? "
      params_arr << ended_at.strip
    end
    unless is_visited.nil? or is_visited == "-1"
      condition_sql += " and o.is_visited = ? "
      params_arr << is_visited.to_i
    end
    return [condition_sql, params_arr]
  end

  #获取需要回访的订单
  def self.get_revisit_orders(store_id, started_at, ended_at, is_visited, is_time, time, is_price, price)
    base_sql = "select o.customer_id from orders o
      where o.store_id = #{store_id.to_i} and o.status != #{STATUS[:DELETED]} "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    group_by_sql = ""

    if !is_time.nil? and !time.nil? and !time.strip.empty?
      group_by_sql += " group by o.customer_id having count(o.id) >= ? "
      params_arr << time.to_i
    end
    if !is_price.nil? and !price.nil? and !price.strip.empty?
      group_by_sql == "" ? group_by_sql = " group by o.customer_id having sum(o.price) >= ? " : group_by_sql += " or sum(o.price) >= ? "
      params_arr << price.to_i
    end
    params_arr[0] = base_sql + condition_sql + group_by_sql
    return Order.find_by_sql(params_arr).collect{ |i| i.customer_id }
  end

  #组装查询customer的sql
  def self.generate_customer_sql(condition_sql, params_arr, store_id, started_at, ended_at, is_visited,
      is_vip, is_time, time, is_price, price, is_birthday)
    customer_condition_sql = condition_sql
    customer_params_arr = params_arr.collect { |p| p }
    unless is_vip.nil? or is_vip == "-1"
      customer_condition_sql += " and cu.is_vip = ? "
      customer_params_arr << is_vip.to_i
    end
    unless is_birthday.nil?
      customer_condition_sql += " and datediff(now(), cu.birthday)%365 >= 355 "
    end
    customer_ids = self.get_revisit_orders(store_id, started_at, ended_at, is_visited, is_time, time, is_price, price)
    unless customer_ids.nil? or customer_ids.blank?
      customer_condition_sql += " and cu.id in (?) "
      customer_params_arr << customer_ids
    end
    return [customer_params_arr, customer_condition_sql, customer_ids]
  end

  #根据需要回访的订单列出客户
  def self.get_order_customers(store_id, started_at, ended_at, is_visited, is_time, time, is_price, 
      price, is_vip, is_birthday, page)
    customer_sql = "select cu.id cu_id, cu.name, cu.mobilephone, cn.num, o.code, o.id o_id from customers cu
      inner join orders o on o.customer_id = cu.id left join car_nums cn on cn.id = o.car_num_id
      where cu.status = #{Customer::STATUS[:NOMAL]} and o.store_id = #{store_id.to_i} and o.status != #{STATUS[:DELETED]} "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    customer_condition_sql = self.generate_customer_sql(condition_sql, params_arr, store_id, started_at,
      ended_at, is_visited, is_vip, is_time, time, is_price, price, is_birthday)
    customer_condition_sql[0][0] = customer_sql + customer_condition_sql[1]
    return customer_condition_sql[2].blank? ? [] :
      Customer.paginate_by_sql(customer_condition_sql[0], :per_page => 10, :page => page)
  end

  #查询需要发短信的用户
  def self.get_message_customers(store_id, started_at, ended_at, is_visited, is_time, time, is_price,
      price, is_vip, is_birthday)
    customer_sql = "select cu.id cu_id, cu.name from customers cu where cu.status = #{Customer::STATUS[:NOMAL]} "
    customer_condition_sql = self.generate_customer_sql("", [""], store_id, started_at, ended_at, is_visited,
      is_vip, is_time, time, is_price, price, is_birthday)
    condition_arr = customer_condition_sql[0]
    condition_sql = customer_condition_sql[1]
    condition_arr[0] = customer_sql + condition_sql
    return customer_condition_sql[2].blank? ? [] : Customer.find_by_sql(condition_arr)
    
  end

  def self.one_customer_orders(status, store_id, customer_id, pre_page, page)
    @orders = Order.paginate_by_sql(["select * from orders where status != ? and store_id = ? and customer_id = ?
        order by created_at desc", status, store_id, customer_id], :per_page => pre_page, :page => page)
  end

  #施工中的订单
  def self.working_orders status,store_id
    Order.find_by_sql("select o.id,c.num from orders o inner join car_nums c on c.id=o.car_num_id where o.status=#{status}
      and o.store_id=#{store_id} order by o.created_at")
  end

  def self.search_by_car_num store_id,car_num
    customer = nil
    working_orders = []
    old_orders = []
    sql = "select c.id customer_id,c.name,c.mobilephone,c.other_way email,c.birthday birth,cn.buy_year year,cn.id car_num_id,cn.num,cm.name model_name,cb.name brand_name
      from customer_num_relations cnr
      inner join car_nums cn on cn.id=cnr.car_num_id and cn.num='#{car_num}'
      inner join customers c on c.id=cnr.customer_id and c.status=#{Customer::STATUS[:NOMAL]}
      left join car_models cm on cm.id=cn.car_model_id
      left join car_brands cb on cb.id=cm.car_brand_id "
    customer = CustomerNumRelation.find_by_sql sql
    if customer && customer.size > 0
      customer = customer[0]
      customer.birth = customer.birth.strftime("%Y-%m-%d")  if customer.birth
      orders = Order.find_by_sql("select * from orders o where o.car_num_id=#{customer.car_num_id}
        and o.status!=#{STATUS[:DELETED]} and o.status != #{STATUS[:INNORMAL]} and o.store_id=#{store_id} order by o.created_at desc")
      (orders || []).each do |order|
        order_hash = order
        #puts order_hash
        order_hash[:products] = []
        order.order_prod_relations.collect{|r|
          product = r.product          
          if product
            p = Hash.new
            p[:name] = product.name
            p[:price] = r.price.to_f * r.pro_num.to_i
            p
            order_hash[:products] << p
          end          
        }
        order_hash[:pay_type] = order.order_pay_types.collect{|type|
          OrderPayType::PAY_TYPES_NAME[type.pay_type]
        }.join(",")
        #if order.sale_id
        #  s = Hash.new
        #  s[:name] = "huodong"
        #  s[:price] = 12
        #  s[:num] = 22
        #  order_hash[:products] << s
        #end
        #if order.c_pcard_relation_id
        #
        #end
        #if order.c_svc_relation_id
        #
        #end
        front_staff = Staff.find_by_id_and_store_id order.front_staff_id,store_id
        order_hash[:staff] = front_staff.name if front_staff
        if order.status == STATUS[:BEEN_PAYMENT]
          old_orders << order_hash
        else
          working_orders << order_hash
        end
      end
      working_orders = working_orders.first if working_orders.size > 0
      #puts old_orders.to_json,working_orders.to_json,customer.to_json
    else

    end
    [customer,working_orders,old_orders]
  end

  def self.get_brands_products store_id
    arr = []
    brands = CarBrand.all :order => "id"
    car_models = CarModel.all.group_by { |cm| cm.car_brand_id  }
    brand_arr = []
    (brands || []).each do |brand|
      b = brand
      b[:models] = car_models[brand.id] unless car_models.empty? and car_models[brand.id] #brand.car_models
      brand_arr << b
    end
    arr << brand_arr
    product_arr = []
    clean_arr = []
    prod_arr = []
    maint_arr = []
    products = Product.find_all_by_store_id_and_status store_id, Product::IS_VALIDATE[:YES]
    (products || []).each do |p|
      h = Hash.new
      h[:id] = p.id
      h[:name] = p.name
      h[:price] = p.sale_price
      h[:img] = (p.img_url.nil? or p.img_url.empty?) ? "" : p.img_url.gsub("img#{p.id}","img#{p.id}_#{Constant::P_PICSIZE[1]}")
      if p.types.to_i <= Product::TYPES_NAME[:OTHER_PROD]
        prod_arr << h
      elsif p.types.to_i == Product::PRODUCT_END
        clean_arr << h
      elsif p.types.to_i > Product::PRODUCT_END
        maint_arr << h
      end
    end
    count = clean_arr.length
    product_arr << clean_arr
    product_arr << maint_arr
    product_arr << prod_arr
    cards = PackageCard.find_all_by_store_id_and_status store_id, PackageCard::STAT[:NORMAL]

    product_arr << (cards || []).collect{|c|
      h = Hash.new
      h[:id] = c.id
      h[:name] = c.name
      h[:price] = c.price
      h[:img] = c.img_url
      h
    }
    arr << product_arr
    count = maint_arr.length if count < maint_arr.length
    count = prod_arr.length if count < prod_arr.length
    count = cards.length if count < cards.length
    product_arr << count
    arr
  end

  def self.one_order_info(order_id)
    return Order.find_by_sql(["select o.id, o.code, o.created_at, o.sale_id, o.price, o.c_pcard_relation_id, o.store_id,
      o.is_free, o.c_svc_relation_id, c.name front_s_name, c1.name cons_s_name1,
      c2.name cons_s_name2, o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2
      from orders o left join customers c on c.id = o.front_staff_id left join customers c1 on c1.id = o.cons_staff_id_1
      left join customers c2 on c2.id = o.cons_staff_id_2 where o.id = ?", order_id])
  end

  #arr = [车牌和用户信息，选择的产品和服务，相关的活动，相关的打折卡，选择的套餐卡，状态，总价]
  def self.pre_order store_id,car_num,brand,car_year,user_name,phone,email,birth,prod_ids,res_time
    arr  = []
    status = 0
    total = 0
    Customer.transaction do
      #begin
      carNum = CarNum.find_by_num car_num
      customer = nil
      if carNum
        customer_car_relation = CustomerNumRelation.find_by_car_num_id carNum.id
        if customer_car_relation
          if customer_car_relation.customer.mobilephone == phone
            customer = customer_car_relation.customer
          else
            customer = Customer.create(:name => user_name,:mobilephone => phone,:other_way => email,
              :birthday => birth,:status => Customer::STATUS[:NOMAL])
            customer_car_relation = CustomerNumRelation.create(:car_num_id => carNum.id, :customer => customer) if customer
          end
        else
          customer = Customer.find_by_mobilephone phone
          customer = Customer.create(:name => user_name,:mobilephone => phone,:other_way => email,
            :birthday => birth,:status => Customer::STATUS[:NOMAL]) if customer.nil?
          customer_car_relation = CustomerNumRelation.create(:car_num_id => carNum.id, :customer => customer)
        end
      else
        m = CarModel.find_by_car_brand_id_and_id brand.split("_")[0].to_i,brand.split("_")[1].to_i
        if m
          customer = Customer.find_by_mobilephone phone
          customer = Customer.create(:name => user_name,:mobilephone => phone,:other_way => email,
            :birthday => birth,:status => Customer::STATUS[:NOMAL]) if customer.nil?
          carNum = CarNum.create(:num => car_num, :car_model_id => m.id,:buy_year => car_year)
          CustomerNumRelation.create(:car_num_id => carNum.id,:customer_id => customer.id) if carNum && customer
        end
      end
      info = Hash.new
      info[:c_id] = customer.id
      info[:car_num] = car_num
      info[:c_name] = customer.name
      info[:phone] = phone
      info[:car_brand] = carNum.car_model.car_brand.name + "-" + carNum.car_model.name
      info[:car_num_id] = carNum.id
      ids = []
      prod_ids.split(",").each do |p_id|
        ids << p_id.split("_")[0].to_i if p_id.split("_")[1].to_i < 3
      end

      products = Product.find(:all, :conditions => ["id in (?) and is_service = #{Product::PROD_TYPES[:SERVICE]}", ids])
      unless products.blank?
        service_ids = products.collect { |p| p.id  }
        time_arr = Station.arrange_time store_id, service_ids, res_time
        info[:start] = time_arr[0]
        info[:end] = time_arr[1]
        info[:station_id] = time_arr[2]
        if info[:station_id].to_i == 0
          status = 2
        end
      else
        info[:start] = ""
        info[:end] = ""
        info[:station_id] = ""
        status = 1
      end
      arr << info
      #根据产品找活动，打折卡，套餐卡
      p_cards = []
      prod_arr = []
      sale_arr = []
      svcard_arr = []
      prod_ids.split(",").each do |id|
        if id.split("_")[1].to_i == 3
          #套餐卡
          user_p_card = CPcardRelation.find_by_package_card_id_and_customer_id id.split("_")[0].to_i, customer.id
          has_p_card = 0
          p_c = Hash.new
          if user_p_card && user_p_card.package_card.status == PackageCard::STAT[:NORMAL] && user_p_card.package_card.store_id = store_id
            has_p_card = 1
            p_c = user_p_card.package_card
            p_c[:products] = p_c.pcard_prod_relations.collect{|r|
              p = Hash.new
              p[:name] = r.product.name
              p[:num] = user_p_card.get_prod_num r.product_id
              p[:p_card_id] = r.package_card_id
              p[:product_id] = r.product_id
              p[:product_price] = r.product.sale_price
              p[:selected] = 1
              p
            }
            p_c[:has_p_card] = has_p_card
            p_c[:show_price] = p_c[:price]
            p_cards << p_c
          else
            p_c = PackageCard.find_by_id_and_status_and_store_id id.split("_")[0].to_i,PackageCard::STAT[:NORMAL],store_id
            if p_c
              p_c[:products] = p_c.pcard_prod_relations.collect{|r|
                p = Hash.new
                p[:name] = r.product.name
                p[:num] = r.product_num
                p[:p_card_id] = r.package_card_id
                p[:product_id] = r.product_id
                p[:product_price] = r.product.sale_price
                p[:selected] = 1
                p
              }
            end
            p_c[:has_p_card] = has_p_card
            p_c[:show_price] = p_c[:price]
            p_cards << p_c
            total += p_c.price
          end
        else
          #产品
          prod = Product.find_by_store_id_and_id_and_status store_id,id.split("_")[0].to_i,Product::IS_VALIDATE[:YES]
          if prod
            product = Hash.new
            product[:id] = prod.id
            product[:name] = prod.name
            product[:price] = prod.sale_price
            product[:count] = 1
            prod_arr << product
            total += product[:price]
            #产品相关的活动
            if prod.sale_prod_relations
              prod.sale_prod_relations.each{|r|
                if r.sale && r.sale.status == Sale::STATUS[:RELEASE]
                  s = Hash.new
                  s[:sale_id] = r.sale_id
                  s[:sale_name] =r.sale.name
                  if r.sale.disc_types == Sale::DISC_TYPES[:FEE]
                    s[:price] = r.sale.discount
                  elsif r.sale.disc_types == Sale::DISC_TYPES[:DIS]
                    s[:price] = prod.sale_price * (10 - r.sale.discount) / 10
                  end
                  s[:selected] = 0
                  s[:show_price] = "-" + s[:price].to_s
                  sale_arr << s
                  total -= s[:price]
                end
              }
            end
            #产品相关的打折卡
            if prod.svcard_prod_relations
              prod.svcard_prod_relations.each{|r|
                if r.sv_card
                  s = Hash.new
                  s[:scard_id] = r.sv_card_id
                  s[:scard_name] = r.sv_card.name
                  s[:scard_discount] = r.sv_card.discount
                  s[:price] = prod.sale_price * (10 - r.sv_card.discount) / 10
                  s[:selected] = 0
                  s[:show_price] = "-" + s[:price].to_s
                  svcard_arr << s
                  total -= s[:price]
                end
              }
            end

          end
        end
      end if prod_ids && carNum && customer
      status = 1 if status == 0
      arr << prod_arr
      arr << sale_arr
      arr << svcard_arr
      arr << p_cards
      arr << status
      arr << total
      #rescue
      #arr = [nil,[],[],[],[],status,total]
      #end
    end
    arr
  end

  #获取产品相关的活动，打折卡，套餐卡
  def self.get_prod_sale_card prods
    arr = prods.split(",")
    prod_arr = []
    sale_arr = []
    svcard_arr = []
    pcard_arr = []
    arr.each do |p|
      if p.split("_")[0].to_i == 0
        #p  0_id_count
        prod_arr << p.split("_")
      elsif p.split("_")[0].to_i == 1
        #p 1_id
        sale_arr << p.split("_")
      elsif p.split("_")[0].to_i == 2
        #p 2_id
        svcard_arr << p.split("_")
      elsif p.split("_")[0].to_i == 3
        #p 3_id_has_p_card_prodId=prodId
        pcard_arr << p.split("_")
      end
    end
    [prod_arr,sale_arr,svcard_arr,pcard_arr]
  end

  #生成订单
  def self.make_record c_id,store_id,car_num_id,start,end_at,prods,price,station_id,user_id
    #puts c_id,store_id,car_num_id,start,end_at,prods,price,station_id,user_id,"---------------------"
    arr = []
    status = 0
    order = nil
    Order.transaction do
      begin
        arr = self.get_prod_sale_card prods
        sale_id = arr[1].size > 0 ? arr[1][0][1] : ""
        svcard_id = arr[2].size > 0 ? arr[2][0][1] : ""
        pcard_id = arr[3].size > 0 ? arr[3][0][1] : ""
        #new order
        order = Order.create({
            :code => MaterialOrder.material_order_code(store_id.to_i),
            :car_num_id => car_num_id,
            :status => Order::STATUS[:INNORMAL],
            :price => price,
            :is_billing => false,
            :front_staff_id => user_id,
            :customer_id => c_id,
            :store_id => store_id,
            :is_visited => IS_VISITED[:NO]
          })
        if order
          hash = Hash.new
          x = 0
          cost_time = 0
          prod_ids = []
          is_has_service = false #用来记录是否有服务
          #创建订单的相关产品 OrdeProdRelation
          (arr[0] || []).each do |prod|
            product = Product.find_by_id_and_store_id_and_status prod[1],store_id,Product::IS_VALIDATE[:YES]
            if product
              OrderProdRelation.create(:order_id => order.id, :product_id => prod[1],
                :pro_num => prod[2], :price => product.sale_price)
              x += 1 if product.is_service?
              cost_time += product.cost_time.to_i
              prod_ids << product.id if product.is_service
              is_has_service = true if product.is_service
            end
          end
          hash[:types] = x > 0 ? TYPES[:SERVICE] : TYPES[:PRODUCT]
          #订单相关的活动
          if sale_id != "" && Sale.find_by_id_and_store_id_and_status(sale_id,store_id,Sale::STATUS[:RELEASE])
            hash[:sale_id] = sale_id
          end
          #订单相关的打折卡
          if svcard_id != "" && SvCard.find_by_id(svcard_id)
            c_sv_relation = CSvcRelation.find_by_customer_id_and_sv_card_id c_id,svcard_id
            c_sv_relation = CSvcRelation.create(:customer_id => c_id, :sv_card_id => svcard_id) if c_sv_relation.nil?
            hash[:c_svc_relation_id] = c_sv_relation.id if c_sv_relation

          end
          #订单相关的套餐卡
          if pcard_id != ""
            pcard = PackageCard.find_by_id_and_store_id_and_status(pcard_id,store_id,PackageCard::STAT[:NORMAL])
            if pcard
              c_pcard_relation = CPcardRelation.find_by_customer_id_and_package_card_id_and_status c_id,pcard.id, CPcardRelation::STATUS[:NORMAL]
              if c_pcard_relation && arr[3][0][2].to_i == 1
                p_ids = arr[3][0][3].split("-")
                content = c_pcard_relation.get_content p_ids
                c_pcard_relation.update_attribute(:content,content)
              end
              if c_pcard_relation.nil? && arr[3][0][2].to_i == 0
                c_pcard_relation = CPcardRelation.create(:customer_id => c_id, :package_card_id => pcard.id,
                  :status => CPcardRelation::STATUS[:NORMAL],
                  :content => CPcardRelation.set_content(pcard.id))
              end
              hash[:c_pcard_relation_id] = c_pcard_relation.id if c_pcard_relation
            end
          end

          if is_has_service
            #创建工位订单
            station = Station.find_by_id_and_status station_id, Station::STAT[:NORMAL]
            unless station
              arrange_time = Station.arrange_time(store_id,prod_ids,nil)
              if arrange_time[2] > 0
                station_id = arrange_time[2]
                station = Station.find_by_id_and_status station_id, Station::STAT[:NORMAL]
              end
            end
            if station
              woTime = WkOrTime.find_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i
              if woTime
                t =  woTime.current_time.to_datetime + Constant::W_MIN.minutes
                start  = t > start.to_datetime ? t : start.to_datetime
                end_at = start + cost_time.minutes
                woTime.update_attributes(:current_time => end_at.strftime("%Y%m%d%H%M").to_i, :wait_num => woTime.wait_num.to_i + 1)
              else
                end_at = start.to_datetime + cost_time.minutes
                WkOrTime.create(:current_time => end_at.strftime("%Y%m%d%H%M"), :current_day => Time.now.strftime("%Y%m%d").to_i,
                  :station_id => station_id, :worked_num => 1)
              end
              work_order = WorkOrder.create({
                  :order_id => order.id,
                  :current_day => Time.now.strftime("%Y%m%d"),
                  :station_id => station_id,
                  :store_id => store_id,
                  :status => (woTime.nil? ? WorkOrder::STAT[:SERVICING] : WorkOrder::STAT[:WAIT]),
                  :started_at => start,
                  :ended_at => end_at
                })
              hash[:station_id] = station_id
              station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i
              hash[:cons_staff_id_1] = station_staffs[0].staff_id if station_staffs.size > 0
              hash[:cons_staff_id_2] = station_staffs[1].staff_id if station_staffs.size > 1
              hash[:started_at] = start
              hash[:ended_at] = end_at
              hash[:status] = STATUS[:NORMAL]
              puts hash
              order.update_attributes hash
              status = 1
            else
              status = 3
            end
          else
            hash[:station_id] = ""
            hash[:cons_staff_id_1] = ""
            hash[:cons_staff_id_2] = ""
            hash[:started_at] = start
            hash[:ended_at] = end_at
            hash[:status] = STATUS[:WAIT_PAYMENT]
            order.update_attributes hash
            status = 1
          end
        end
      rescue
        status = 2
      end
    end
    arr[0] = status
    arr[1] = order
    arr
  end

  #返回订单的相关信息
  def get_info
    hash = Hash.new
    hash[:id] = self.id
    hash[:code] = self.code
    car_num = self.car_num
    hash[:car_num] = car_num.num
    hash[:username] = self.customer.name
    hash[:start] = self.started_at.strftime("%Y-%m-%d %H:%M") if self.started_at
    hash[:end] = self.ended_at.strftime("%Y-%m-%d %H:%M") if self.ended_at
    hash[:total] = self.price
    content = ""
    realy_price = 0
    hash[:products] = self.order_prod_relations.collect{|r|
      h = Hash.new
      h[:name] = r.product.name
      h[:price] = r.price
      realy_price += r.price
      h[:num] = r.pro_num.to_i
      h[:type] = 0
      content += h[:name] + ","
      h
    }
    hash[:content] = content.chomp(",")
    unless self.sale_id.blank?
      h = {}
      sale = self.sale
      h[:name] = sale.name
      h[:price] = sale.disc_types == Sale::DISC_TYPES[:FEE] ? sale.discount : realy_price * (10 - sale.discount) / 10
      h[:type] = 1
      hash[:sale] = h
    end
    if not self.c_svc_relation_id.blank?
      h = {}
      sv_card = self.c_svc_relation.sv_card
      h[:name] = sv_card.name
      h[:price] = sv_card.price * (10 - sv_card.discount) / 10
      h[:discount] = sv_card.discount
      h[:type] = 2
      hash[:c_svc_relation] = h
    end
    if not self.c_pcard_relation_id.blank?
      h = {}
      pcard = self.c_pcard_relation.package_card
      h[:name] = pcard.name
      h[:price] = pcard.price
      h[:type] = 3
      h[:prods] = self.c_pcard_relation.content.split(",").collect{|p|
        s = {}
        s[:name] = p.split("-")[1]
        s[:num] = p.split("-")[2]
        s
      }
      hash[:c_pcard_relation] =  h
    end
    hash
  end

  #支付订单根据选择的支付方式
  def self.pay order_id,store_id,please,pay_type,billing,code
    #puts order_id,store_id,please,pay_type,billing,code
    order = Order.find_by_id_and_store_id order_id,store_id
    status = 0
    if order
      Order.transaction do
        begin
          hash = Hash.new
          hash[:is_billing] = billing.to_i == 0 ? false : true
          hash[:is_pleased] = please.to_i == 0 ? false : true
          hash[:status] = STATUS[:BEEN_PAYMENT]
          #如果是选择储值卡支付
          if pay_type.to_i == OrderPayType::PAY_TYPES[:SV_CARD] && order.c_svc_relation_id && code
            #c_svc_relation = CSvcRelation.find_by_id order.c_svc_relation_id
            #if c_svc_relation && c_svc_relation.left_price.to_f >= order.price.to_f
            content = "订单号为：#{order.code},消费：#{order.price}."
            #sv_use_record = SvcardUseRecord.create(:c_svc_relation_id => c_svc_relation.id,
            #                                       :types => SvcardUseRecord::TYPES[:OUT],
            #                                       :use_price => order.price,
            #                                       :content => content,
            #                                       :left_price => (c_svc_relation.left_price - order.price)
            #)
            #c_svc_relation.update_attribute(:left_price,sv_use_record.left_price) if sv_use_record
            svc_return_record = SvcReturnRecord.find_all_by_store_id(store_id,:order => "created_at desc", :limit => 1)
            if svc_return_record.size > 0

              total = svc_return_record[0].total_price - order.price
              SvcReturnRecord.create(:store_id => store_id, :price => order.price, :types => SvcReturnRecord::TYPES[:OUT],
                :content => content, :target_id => order.id, :total_price => total)
            else
              SvcReturnRecord.create(:store_id => store_id, :price => order.price, :types => SvcReturnRecord::TYPES[:OUT],
                :content => content, :target_id => order.id, :total_price => -order.price)
            end
            order.update_attributes hash
            OrderPayType.create(:order_id => order_id, :pay_type => pay_type.to_i, :price => order.price)
            status = 1
            #else
            #  status = 3
            #end
          else
            order.update_attributes hash
            OrderPayType.create(:order_id => order_id, :pay_type => pay_type.to_i, :price => order.price)
            status = 1
          end
        rescue

        end
      end
    else
      status = 2
    end
    [status]
  end

  def self.checkin store_id,car_num,brand,car_year,user_name,phone,email,birth
    carNum = CarNum.find_by_num car_num
    customer = nil
    status = 0
    Customer.transaction do
      begin
        if carNum
          customer_car_relation = CustomerNumRelation.find_by_car_num_id carNum.id
          if customer_car_relation
            if customer_car_relation.customer.mobilephone == phone
              customer = customer_car_relation.customer
            else
              customer = Customer.create(:name => user_name,:mobilephone => phone,:other_way => email,
                :birthday => birth,:status => Customer::STATUS[:NOMAL])
              customer_car_relation = CustomerNumRelation.create(:car_num_id => carNum.id, :customer => customer) if customer
            end
          else
            customer = Customer.find_by_mobilephone phone
            customer = Customer.create(:name => user_name,:mobilephone => phone,:other_way => email,
              :birthday => birth,:status => Customer::STATUS[:NOMAL]) if customer.nil?
            customer_car_relation = CustomerNumRelation.create(:car_num_id => carNum.id, :customer => customer)
          end
        else
          m = CarModel.find_by_car_brand_id_and_id brand.split("_")[0].to_i,brand.split("_")[1].to_i
          if m
            customer = Customer.find_by_mobilephone phone
            customer = Customer.create(:name => user_name,:mobilephone => phone,:other_way => email,
              :birthday => birth,:status => Customer::STATUS[:NOMAL]) if customer.nil?
            carNum = CarNum.create(:num => car_num, :car_model_id => m.id,:buy_year => car_year)
            CustomerNumRelation.create(:car_num_id => carNum.id,:customer_id => customer.id) if carNum && customer
          end
        end
        status = 1 if carNum
      rescue
        status = 2
      end
    end
    status
  end
end
