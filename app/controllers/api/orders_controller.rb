#encoding: utf-8
require 'json'
require "uri"
class Api::OrdersController < ApplicationController
  #首页,登录后的页面
  def index_list
    status = 0
    begin
      reservations = Reservation.store_reservations params[:store_id]
      orders = Order.working_orders params[:store_id]
      orders = orders.group_by{|order| order.status}
      status = 1
    rescue
      status = 2
    end
    render :json => {:status => status,:orders => orders,:reservations => reservations}.to_json
  end

  def login
    staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:user_name], Staff::VALID_STATUS])
    info = ""
    if  staff.nil? or !staff.has_password?(params[:user_password])
      info = "用户名或密码错误"
    elsif staff.store.nil? or staff.store.status != Store::STATUS[:OPENED]
      info = "用户不存在"
    else
      cookies[:user_id]={:value => staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>staff.name, :path => "/", :secure  => false}
      session_role(cookies[:user_id])
      #if has_authority?
      info = ""
      #else
      #cookies.delete(:user_id)
      #cookies.delete(:user_name)
      #cookies.delete(:user_roles)
      #cookies.delete(:model_role)
      #info = "抱歉，您没有访问权限"
      #end
    end
    render :json => {:staff => staff, :info => info}.to_json
  end
  #根据车牌号查询客户
  def search_car
    order = Order.search_by_car_num params[:store_id],params[:car_num], nil
    result = {:status => 1,:customer => order[0],:working => order[1], :old => order[2], :package_cards => order[3] }.to_json
    render :json => result
  end

  #查看订单
  def show_car
    order = Order.search_by_car_num params[:store_id],params[:car_num], params[:car_id]
    result = {:status => 1,:customer => order[0],:working => order[1], :old => order[2], :package_cards => order[3] }.to_json
    render :json => result
  end

  #发送验证码
  def send_code
    message = MessageRecord.send_code params[:order_id],params[:phone]
    render :json => {:status => message}
  end
  #下单
  def add
    user_id = params[:user_id].nil? ? cookies[:user_id] : params[:user_id]
    order = Order.make_record params[:c_id],params[:store_id],params[:car_num_id],params[:start],
      params[:end],params[:prods],params[:price],params[:station_id],user_id
    info = order[1].nil? ? nil : order[1].get_info
    str = if order[0] == 0 || order[0] == 2
      "数据出现异常"
    elsif order[0] == 1
      "success"
      #    elsif order[0] == 3
      #      "没可用的工位了"
    end
    render :json => {:status => order[0], :content => str, :order => info}
  end
  #付款
  def pay
    order = Order.pay(params[:order_id], params[:store_id], params[:please],
      params[:pay_type], params[:billing], params[:code], params[:is_free], params[:appid])
    content = ""
    if order[0] == 0
      content = ""
    elsif order[0] == 1
      content = "success"
    elsif order[0] == 2
      content = "订单不存在"
    elsif order[0] == 3
      content = "储值卡余额不足，请选择其他支付方式"
    end
    render :json => {:status => order[0], :content => content}
  end
  #投诉
  def complaint
    complaint = Complaint.mk_record params[:store_id],params[:order_id],params[:reason],params[:request]
    render :json => {:status => (complaint.nil? ? 0 : 1)}
  end

  #车品牌
  def brands_products
    items = Order.get_brands_products params[:store_id]
    render :json => {:status => 1, :all_infos => items}
  end

  #点击完成按钮，确定选择的产品和服务
  def finish
    prod_id = params[:prod_ids] #"10_3,311_0,226_2,"
    prod_id = prod_id[0...(prod_id.size-1)] if prod_id
    pre_arr = Order.pre_order params[:store_id],params[:carNum],params[:brand],params[:year],params[:userName],params[:phone],
      params[:email],params[:birth],prod_id,params[:res_time],params[:sex], params[:from_pcard].to_i
    content = ""
    if pre_arr[5] == 0
      content = "数据出现异常"
    elsif pre_arr[5] == 1
      content = "success"
    elsif pre_arr[5] == 2
      content = "选择的产品和服务无法匹配工位"
    elsif pre_arr[5] == 3
      content = "所购买的服务需要多个工位，请分别下单！"
    elsif pre_arr[5] == 4
      content = "工位上暂无技师"
    end
    result = {:status => pre_arr[5], :info => pre_arr[0], :products => pre_arr[1], :sales => pre_arr[2],
      :svcards => pre_arr[3], :pcards => pre_arr[4], :total => pre_arr[6], :content  => content}
    render :json => result.to_json
  end

  #确认预约信息
  def confirm_reservation
    reservation = Reservation.find_by_id_and_store_id params[:r_id].to_i,params[:store_id]
    customer = nil
    product_ids = []
    if reservation && reservation.status == Reservation::STATUS[:normal]
      time = reservation.res_time
      if params[:reserv_at]
        time = (params[:reserv_at].to_s + ":00").gsub(".","-")
      end
      reservation.update_attributes(:status => Reservation::STATUS[:confirmed],:res_time => time) if params[:status].to_i == 0     #确认预约
      reservation.update_attribute(:status, Reservation::STATUS[:cancel]) if params[:status].to_i == 1     #取消预约
      r_products = ResProdRelation.find(:all, :select => "product_id", :conditions => ["reservation_id = ?", reservation.id])
      product_ids = r_products.collect { |r_p| r_p.product_id }

      if params[:reserv_at]
        customer = Hash.new
        car_num = reservation.car_num
        c = Customer.find_by_sql(["select c.* from customers c left join customer_num_relations cnr
          on cnr.customer_id = c.id where car_num_id = ?", car_num.id])[0]
        customer[:carNum] = car_num.num
        customer[:car_num_id] = reservation.car_num_id
        customer[:name] = c.name
        customer[:customer_id] = c.id
        customer[:reserv_at] = reservation.res_time
        customer[:phone] = c.mobilephone if c
        customer[:email] = c.other_way if c
        customer[:birth] = c.birthday.strftime("%Y-%m-%d") if c and c.birthday
        customer[:year] = car_num.buy_year
      end
    end
    items = Order.get_brands_products params[:store_id]
    reservations = Reservation.store_reservations params[:store_id]
    render :json => {:status => 1, :reservation => reservations, :customer => customer, :product_ids => product_ids,
      :all_infos => items}
  end

  #刷新返回预约信息
  def refresh
    reservations = Reservation.store_reservations params[:store_id]
    render :json => {:status => 1, :reservation => reservations }
  end

  #查询订单后的支付，取消订单
  def pay_order
    order = Order.find_by_id params[:order_id]
    status = 0
    if params[:opt_type].to_i == 1
      if order && (order.status == Order::STATUS[:NORMAL] or order.status == Order::STATUS[:SERVICING] or order.status == Order::STATUS[:WAIT_PAYMENT])
        #退回使用的套餐卡次数
        order.return_order_pacard_num
        #如果是产品,则减掉要加回来
        order.return_order_materials
        #如果存在work_order,取消订单后设置work_order以及wk_or_times里面的部分数值
        order.rearrange_station
        order.update_attribute(:status, Order::STATUS[:DELETED])
        status = 1
      else
        status = 2
      end
      info = order.nil? ? nil : order.get_info
      render :json  => {:status => status}
    else
      info = order.nil? ? nil : order.get_info
      status = 1
      render :json  => {:status => status, :order => info}
    end

  end

  def checkin
    order = Order.checkin params[:store_id],params[:carNum],params[:brand],params[:year],params[:userName],params[:phone],
      params[:email],params[:birth],params[:sex]
    content = ""
    if order == 1
      content = "success"
    else
      content = "数据操作失败"
    end
    render :json => {:status => order, :content => content}
  end

  def sync_orders_and_customer
    sync_info = JSON.parse(params[:syncInfo])
    flag = true
    Customer.transaction do
      # begin
      #同步客户信息
      customers_info = sync_info["customer"]
      customers_info.each do |customer|
        old_customer = Customer.find_by_status_and_mobilephone(Customer::STATUS[:NOMAL], customer["phone"])
        old_customer.update_attributes(:name => customer["name"].strip, :other_way => customer["email"],
          :birthday => customer["birth"], :sex => customer["sex"]) if old_customer
        carNum = CarNum.find_by_num(customer["carNum"])
        Customer.create_single_cus(old_customer, carNum, customer["phone"], customer["carNum"], customer["name"],
          customer["email"], customer["birth"], customer["year"], customer["brand"].split("_")[1].to_i, customer["sex"], nil, nil, customer["store_id"])
      end

      #同步订单信息
      codes_info = sync_info["code"]
      codes_info.each do |code_info|
        order = Order.find_by_id(code_info["code"])
        if order
          if code_info["status"].to_i == Order::STATUS[:DELETED]
            order.return_order_materials
            order.update_attribute(:status, Order::STATUS[:DELETED])
          elsif code_info["status"].to_i == Order::STATUS[:BEEN_PAYMENT] || Order::STATUS[:FINISHED]
            OrderPayType.create(:pay_type => code_info["pay_type"], :price => code_info["price"],
              :created_at => code_info["time"], :order_id => order.id)
            Complaint.create(:reason => code_info["complaint"]["reason"], :suggestion => code_info["complaint"]["request"],
              :created_at => code_info["time"], :order_id => order.id, :customer_id => order.customer_id) if code_info["complaint"]
            order.c_pcard_relations.each {|cpr| cpr.update_attributes(:status => CPcardRelation::STATUS[:NORMAL])} if order.c_pcard_relations
            CSvcRelation.find_all_by_order_id(order.id).each { |csr| csr.update_attributes(:status => CSvcRelation::STATUS[:valid]) }
            is_free = (code_info["pay_type"].to_i == OrderPayType::PAY_TYPES[:IS_FREE]) ? true : false
            order.update_attributes(:status => code_info["status"].to_i, :is_pleased => code_info["is_please"],
              :is_billing => code_info["billing"].to_i, :is_free => is_free)
          end
        end
      end if codes_info

      orders_info = sync_info["order"]
      orders_info.each do |order_info|
        carNum = CarNum.find_by_num(order_info["carNum"])
        customer_id = carNum.customer_num_relation.customer.id
        is_free = (order_info["pay_type"].to_i == OrderPayType::PAY_TYPES[:IS_FREE]) ? true : false
        order = Order.create(:is_billing => order_info["billing"].to_i, :created_at => order_info["time"], :store_id => order_info["store_id"],
          :price => order_info["price"], :front_staff_id => order_info["user_id"], :is_pleased => order_info["is_please"],
          :status => order_info["status"], :code => MaterialOrder.material_order_code(order_info["store_id"].to_i, order_info["time"]),
          :car_num_id => carNum.try(:id), :customer_id => customer_id, :is_free => is_free)
        prod_arr = Order.get_prod_sale_card(order_info["prods"])
        (prod_arr[0] || []).each do |prod|
          product = Product.find_by_id_and_store_id_and_status(prod[1].to_i,order_info["store_id"],Product::IS_VALIDATE[:YES])
          if product
            order.order_prod_relations.new(:product_id => product.id, :pro_num => prod[2], :total_price => prod[3], :price => product.sale_price, :t_price => product.t_price, :created_at => order_info["time"])
          end
        end
            
        order.order_pay_types.new(:pay_type => order_info["pay_type"], :price => order_info["price"], :created_at => order_info["time"])
        order.complaints.new(:reason => order_info["complaint"]["reason"], :suggestion => order_info["complaint"]["request"],
          :created_at => order_info["time"], :customer_id => order.customer_id) if order_info.keys.include?("complaint")
        (prod_arr[2] || []).each do |svcard|
          sv_card = SvCard.find_by_id(svcard[1].to_i)
          sv_price =SvcardProdRelation.find_by_sv_card_id(sv_card.id)
          if sv_card
            c_svc_status = (order_info["status"].to_i == Order::STATUS[:BEEN_PAYMENT]) ? CSvcRelation::STATUS[:valid] : CSvcRelation::STATUS[:invalid]
            c_svc_r_hash = {:customer_id => customer_id, :sv_card_id => sv_card.id, :is_billing => order_info["billing"].to_i,
              :order_id => order.id, :status => c_svc_status}
            if sv_card.types == SvCard::FAVOR[:SAVE]
              c_svc_r_hash.merge!(:total_price => sv_price.base_price + sv_price.more_price,
                :left_price => sv_price.base_price + sv_price.more_price)
              c_sv_relation = CSvcRelation.create(c_svc_r_hash)
              SvcardUseRecord.create(:c_svc_relation_id => c_sv_relation.id, :types => SvcardUseRecord::TYPES[:IN],
                :use_price => sv_price.base_price + sv_price.more_price,
                :left_price=> sv_price.base_price + sv_price.more_price,:content=>"购买#{sv_card.name}")
            else
              c_sv_relation = CSvcRelation.create(c_svc_r_hash)
            end
            c_s_r = CustomerStoreRelation.find_by_store_id_and_customer_id(order.store_id, order.customer_id)
            c_s_r.update_attributes(:is_vip => Customer::IS_VIP[:VIP])
            #carNum.customer_num_relation.customer.update_attributes(:is_vip => Customer::IS_VIP[:VIP])
          end
        end
        (prod_arr[3] || []).each do |pcard|
          package_card = PackageCard.find_by_id(pcard[1].to_i)
          if order_info["status"].to_i == Order::STATUS[:BEEN_PAYMENT]
            order.c_pcard_relations.new(:customer_id => customer_id, :package_card_id => pcard[1], :status => CPcardRelation::STATUS[:NORMAL], :price => package_card.try(:price), :created_at => order_info["time"])
          else
            order.c_pcard_relations.new(:customer_id => customer_id, :package_card_id => pcard[1], :status => CPcardRelation::STATUS[:INVALID], :price => package_card.try(:price), :created_at => order_info["time"])
          end
        end
        order.save
      end
      # rescue
      #flag = false
      # end
    end
    resp_text = flag ? "success" : "error"
    render :json => {:status => resp_text}
  end

  #发送短信code
  def get_user_svcard
    csvc_relaions = CSvcRelation.find_by_sql(["select csr.* from c_svc_relations csr
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id
      where c.mobilephone = ? and sc.types = 1 and csr.status = ? and ((sc.use_range = #{SvCard::USE_RANGE[:LOCAL]} and sc.store_id = #{params[:store_id]})
        or (sc.use_range = #{SvCard::USE_RANGE[:CHAIN_STORE]} and sc.store_id in (?)) or (sc.use_range = #{SvCard::USE_RANGE[:ALL]}))",
        params[:mobilephone].strip, CSvcRelation::STATUS[:valid], StoreChainsRelation.return_chain_stores(params[:store_id])])
    sum_left_total = csvc_relaions.inject(0){|sum, csv| sum = sum+csv.left_price.to_f}
    record = csvc_relaions[0]
    status = 0
    
    if record.nil?
      message = "账号不存在。"
    else
      if sum_left_total >= params[:price].to_f
        record.update_attribute(:verify_code, proof_code(6))
        status = 1
        send_message = "感谢您使用澜泰储值卡，您本次的消费验证码为：#{record.verify_code}。"
        message = "发送成功。"
      else
        send_message = "余额不足，您的储值卡余额为#{sum_left_total}元。"
        message = "余额不足。"
      end
      message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{params[:mobilephone].strip}&Content=#{URI.escape(send_message)}&Exno=0"
      create_get_http(Constant::MESSAGE_URL, message_route)
    end
    render :json => {:content => message, :status => status}
  end

  #使用储值卡支付
  def use_svcard
    record = CSvcRelation.find_by_sql(["select csr.* from c_svc_relations csr
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id
      where sc.types = 1 and c.mobilephone = ? and csr.verify_code = ? and csr.status = ?",
        params[:mobilephone].strip, params[:verify_code].strip, CSvcRelation::STATUS[:valid]])[0]
    status = 0
    message = "支付失败。"
    price = params[:price].to_f
    if record
      if record.left_price >= price
        left_price = record.left_price - price
        SvcardUseRecord.create(:c_svc_relation_id => record.id, :types => SvcardUseRecord::TYPES[:OUT],
          :use_price => price, :left_price => left_price, :content => params[:content].strip)
        record.update_attribute(:left_price, left_price)
      else
        csvc_relaions = CSvcRelation.find_by_sql(["select csr.* from c_svc_relations csr
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id
 where sc.types = 1 and c.mobilephone = ? and left_price != ? and csr.status = ?
            and ((sc.use_range = #{SvCard::USE_RANGE[:LOCAL]} and sc.store_id = #{params[:store_id]})
        or (sc.use_range = #{SvCard::USE_RANGE[:CHAIN_STORE]} and sc.store_id in (?)) or (sc.use_range = #{SvCard::USE_RANGE[:ALL]}))",
            params[:mobilephone].strip, 0, CSvcRelation::STATUS[:valid], StoreChainsRelation.return_chain_stores(params[:store_id])])
        csvc_relaions.each do |csv|
          if price > 0
            if price - csv.left_price >= 0
              SvcardUseRecord.create(:c_svc_relation_id => csv.id, :types => SvcardUseRecord::TYPES[:OUT],
                :use_price => csv.left_price, :left_price => 0, :content => params[:content].strip)
              price = price - csv.left_price
              csv.update_attribute(:left_price, 0)
            else
              SvcardUseRecord.create(:c_svc_relation_id => csv.id, :types => SvcardUseRecord::TYPES[:OUT],
                :use_price => price, :left_price => csv.left_price - price, :content => params[:content].strip)
              csv.update_attribute(:left_price, csv.left_price - price)
              price = 0
            end
          end
        end
      end
      status = 1
      message = "支付成功。"
    end
    render :json => {:content => message, :status => status}
  end

  #工位完成施工，技师会用手机触发，给工位进行排单
  def work_order_finished
    work_order = WorkOrder.find_by_id(params[:work_order_id])
    if !work_order.nil?
      message = work_order.arrange_station
      if message == "no_next_work_order"
        render :json => {:status => 1, :message => "没有客户继续下单!"}
      else
        render :json => {:status => 1, :message => "排单成功!"}
      end
    else
      render :json => {:status => 0, :message => "没有找到这个订单!"}
    end
  end

  #盘点实数
  def check_num
    data = JSON.parse(params[:data])
    store_id = data["store_id"]
    materials = data["materials"]
    mat_arr = []
    materials.each do |mat|
      material = Material.where("code = #{mat['code']} and store_id = #{store_id} and status = #{Material::STATUS[:NORMAL]}").first
      if material
        material.check_num = mat['check_num']
        mat_arr << material
      else
        mat_arr << nil
      end
    end
    if mat_arr.include?(nil)
      render :json => {:status => "error", :message => "没有材料"}
    else
      if Material.import mat_arr, :on_duplicate_key_update => [:check_num]
        render :json => {:status => "success"}
      else
        render :json => {:status => "error", :message => "更新盘点实数失败"}
      end
    end
  end

  #核实
  def materials_verification
    data = JSON.parse(params[:data])
    store_id = data["store_id"]
    materials = data["materials"]
    mat_arr = []
    materials.each do |mat|
      material = Material.where("code = #{mat['code']} and store_id = #{store_id} and status = #{Material::STATUS[:NORMAL]}").first
      if material
        material.storage = mat['storage'].to_i
        material.check_num = nil
        mat_arr << material
      else
        mat_arr << nil
      end
    end
    if mat_arr.include?(nil)
      render :json => {:status => "error", :message => "没有材料"}
    else
      if Material.import mat_arr, :on_duplicate_key_update => [:check_num, :storage]
        materials = Material.where("store_id = #{store_id} and status = #{Material::STATUS[:NORMAL]}").select("code, name, storage")
        render :json => {:status => "success", :meterials => materials}
      else
        render :json => {:status => "error", :message => "核实材料数量失败"}
      end
    end
  end

  #出库
  def out_materials
    data = JSON.parse(params[:data])
    store_id = data["store_id"].to_i
    materials = data["materials"]
    staff_id = data["staff_id"].to_i
    mat_out_types = data["mat_out_types"]
    mat_arr = []
    materials.each do |mat|
      material = Material.where("code = #{mat['code']} and store_id = #{store_id} and status = #{Material::STATUS[:NORMAL]}").first
      if material && material.storage >= mat['check_num'].to_i
        material.check_num = nil
        material.storage = material.storage - mat['check_num'].to_i
        material.mat_out_orders.new(:staff_id => staff_id, :store_id => store_id,
          :material_num => mat['check_num'].to_i, :price => material.price, :types => mat_out_types)
        mat_arr << material
      else
        mat_arr << nil
      end
    end
    if mat_arr.include?(nil)
      no_enough_storeage = materials - mat_arr
      render :json => {:status => "error", :message => "没有材料或者你的出库数量超过库存数量", :materials => no_enough_storeage}
    else
      Material.transaction do
        begin
          mat_arr.each do |mat|
            mat.save
          end
          materials = Material.where("store_id = #{store_id} and status = #{Material::STATUS[:NORMAL]}").select("code, name, storage")
          render :json => {:status => "success", :materials => materials}
        rescue
          render :json => {:status => "error", :message => "出库失败"}
        end
      end
    end
  end

  #员工登录,如果登录成功，返回正在施工中的订单
  def login_and_return_construction_order
    staff = Staff.find_by_username(params[:username])
    if staff.nil? || !staff.has_password?(params[:user_password])
      #用户名或者密码错误
      render :json => {:status => 0}
    elsif !Staff::VALID_STATUS.include?(staff.status) || staff.store.nil? || staff.store.status != Store::STATUS[:OPENED]
      render :json => {:status => 3, :message => "该用户不存在"}
    else
      #登录成功
      phone_inventory = staff_phone_inventory_permission?([:staffs, :phone_inventory], staff.id) ? 1 : 0
      #是否是技师登录
      
      mat_out_types = MatOutOrder::TYPES
      if staff.type_of_w == Staff::S_COMPANY[:TECHNICIAN]
        #所有的code，材料名称
        render :json => {:status => 1, :store_id => staff.store_id, :staff_id => staff.id, :mat_out_types => mat_out_types, :phone_inventory => phone_inventory}
      else
        render :json => {:status => 2, :phone_inventory => phone_inventory, :staff_id => staff.id, :store_id => staff.store_id, :mat_out_types => mat_out_types}
      end  
    end
  end

  #得到最新的材料
  def get_lastest_materails
    staff = Staff.find_by_id(params[:staff_id])
    if staff
      materials = Material.where("store_id = #{staff.store_id} and status = #{Material::STATUS[:NORMAL]}").select("code, name, storage")
      render :json => {:status => 1, :materials => materials}
    else
      render :json => {:status => 0}
    end
  end

  #返回正在施工中的work_orders
  def get_construction_order
    staff = Staff.find_by_id(params[:staff_id])
    if staff
      current_day = Time.now.strftime("%Y%m%d")
      #      stations = Station.includes(:station_staff_relations => :staff).
      #        where("staffs.id = #{staff.id}").
      #        where("station_staff_relations.store_id = #{staff.store_id}").
      #        where("station_staff_relations.current_day = #{Time.now.strftime("%Y%m%d").to_i}").
      #        where("stations.status = #{Station::STAT[:NORMAL]}")
      #      wo = nil
      #      sta = nil
      #stations.each do |station|
      work_order = WorkOrder.joins([:order => :car_num], :station => {:station_staff_relations => :staff}).
        where("work_orders.store_id = #{staff.store_id}").
        where("work_orders.status = #{WorkOrder::STAT[:SERVICING]}").
        where("stations.status = #{Station::STAT[:NORMAL]}").
        where("work_orders.current_day = #{current_day}").
        where("staffs.id = #{staff.id}").
        where("station_staff_relations.store_id = #{staff.store_id}").
        where("station_staff_relations.current_day = #{Time.now.strftime("%Y%m%d").to_i}").
        select("work_orders.*,car_nums.num as car_num").first
      if work_order
        work_order["coutdown"] = work_order.ended_at - Time.now
        products = Product.where("products.is_service = #{Product::PROD_TYPES[:SERVICE]} and orders.id = #{work_order.order_id}").
          joins(:order_prod_relations => :order).select("name")
        product_names = products.map(&:name).join(",")
        work_order["product_names"] = product_names
        #          wo = work_order
        #          sta = station
        #          break
      end
      #end
      #      else
      #        work_order = nil
      #      end
      #      render :json => {:status => 1, :work_order => wo, :station => sta}
      render :json => {:status => 1, :work_order => work_order, :station => work_order.nil? ? nil : work_order.station}
    else
      render :json => {:status => 0}
    end
  end

  # 点击产品预览后，输入car num 查询api
  def search_by_car_num2
    customer_info = CarNum.get_customer_info_by_carnum(params[:store_id],params[:car_num])
    render :json => {:customer => customer_info, :status => customer_info.nil? ? 0 : 1}
  end

  #终止施工
  def stop_construction
    work_order = WorkOrder.find_by_id(params[:work_order_id])
    work_order.update_attribute(:status, WorkOrder::STAT[:END]) if work_order
    order = work_order.order
    order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order && order.status != Order::STATUS[:BEEN_PAYMENT]
    work_order.arrange_station(nil,nil,true) if work_order
    render :json => {:status => 1}
  end

  #根据物料条形码查询物料
  def search_material
    staff = Staff.find_by_id(params[:staff_id])
    material = Material.where(:code => params[:code], :store_id => staff.store_id, :status => Material::STATUS[:NORMAL]).
      select("name, code, storage, types, status, store_id, created_at, updated_at, remark, check_num, sale_price, unit, is_ignore, material_low, code_img").first if !staff.nil?
    render :json => {:material => material}
  end
  
end
