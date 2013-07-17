#encoding: utf-8
require 'json'
class Api::OrdersController < ApplicationController
  #首页,登录后的页面
  def index_list
    status = 0
    begin
      reservations = Reservation.store_reservations params[:store_id]
      orders = Order.working_orders params[:store_id]
      status = 1
    rescue
      status = 2
    end
    render :json => {:status => status,:orders => orders,:reservations => reservations}.to_json
  end

  def login
    staff = Staff.find_by_username(params[:user_name])
    info = ""
    if  staff.nil? or !staff.has_password?(params[:user_password])
      info = "用户名或密码错误"
    elsif !Staff::VALID_STATUS.include?(staff.status) or staff.store.status != Store::STATUS[:OPENED]
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
    elsif order[0] == 3
      "没可用的工位了"
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
      params[:email],params[:birth],prod_id,params[:res_time],params[:sex]
    content = ""
    if pre_arr[5] == 0
      content = "数据出现异常"
    elsif pre_arr[5] == 1
      content = "success"
    elsif pre_arr[5] == 2
      content = "选择的产品和服务无法匹配工位"
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
      :brands => items[0], :products => items[1], :count => items[1][4]}
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
        order.return_work_orders
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
          order = Order.find_by_code(code_info["code"])
          if code_info["status"].to_i == Order::STATUS[:DELETED]
            order.return_order_materials
            order.update_attribute(:status, Order::STATUS[:DELETED])
          elsif code_info["status"].to_i == Order::STATUS[:BEEN_PAYMENT]
            OrderPayType.create(:pay_type => code_info["pay_type"], :price => code_info["price"],
              :created_at => code_info["time"], :order_id => order.id)
            Complaint.create(:reason => code_info["complaint"]["reason"], :suggestion => code_info["complaint"]["request"],
              :created_at => code_info["time"], :order_id => order.id, :customer_id => order.customer_id) if code_info["complaint"]
            order.c_pcard_relations.each {|cpr| cpr.update_attributes(:status => CPcardRelation::STATUS[:NORMAL])} if order.c_pcard_relations
            CSvcRelation.find_all_by_order_id(order.id).each { |csr| csr.update_attributes(:status => CSvcRelation::STATUS[:valid]) }
            is_free = (code_info["pay_type"].to_i == OrderPayType::PAY_TYPES[:IS_FREE]) ? true : false
            order.update_attributes(:status => Order::STATUS[:BEEN_PAYMENT], :is_pleased => code_info["is_please"],
              :is_billing => code_info["billing"].to_i, :is_free => is_free)
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
              carNum.customer_num_relation.customer.update_attributes(:is_vip => Customer::IS_VIP[:VIP])
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
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id where c.mobilephone = ? and sc.types = 1",
        params[:mobilephone].strip])
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
      message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{params[:mobilephone].strip}&Content=#{send_message}&Exno=0"
      create_get_http(Constant::MESSAGE_URL, message_route)
    end
    render :json => {:content => message, :status => status}
  end

  #使用储值卡支付
  def use_svcard
    record = CSvcRelation.find_by_sql(["select csr.* from c_svc_relations csr
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id
      where sc.types = 1 and c.mobilephone = ? and csr.verify_code = ?",
        params[:mobilephone].strip, params[:verify_code].strip])[0]
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
      left join customers c on c.id = csr.customer_id where c.mobilephone = ? and left_price != ?",
            params[:mobilephone].strip, 0])
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
    current_time = Time.now
    work_order = WorkOrder.find_by_id(params[:work_order_id])
    if work_order
      #把完成的单的状态置为等待付款
      runtime = sprintf('%.2f',(current_time - work_order.started_at)/60).to_f
      work_order.update_attributes(:status => WorkOrder::STAT[:WAIT_PAY], :runtime => runtime)
      order = work_order.order
      if runtime > work_order.cost_time
        staffs = [order.try(:cons_staff_id_1), order.try(:cons_staff_id_2)]
        staffs.each do |staff_id|
          ViolationReward.create(:staff_id => staff_id, :types => ViolationReward::TYPES[:VIOLATION],
          :situation => "订单号#{order.code}超时#{runtime - work_order.cost_time}分钟",
          :status => ViolationReward::STATUS[:NOMAL])
        end
      end
      order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order

      #排下一个单
      next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]}").
                                  where("station_id = #{work_order.station_id}").
                                  where("store_id = #{work_order.store_id}").
                                  where("current_day = #{work_order.current_day}").first
      if next_work_order
        #同一个人的下单，直接紧接着排单
        ended_at = current_time + next_work_order.cost_time*60
        next_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
          :started_at => current_time, :ended_at => ended_at )
        next_order = next_work_order.order
        next_order.update_attribute(:status, Order::STATUS[:SERVICING]) if next_order
      else
        #按照created_at时间来排单
        another_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]}").
                            where("station_id is null").
                            where("store_id = #{work_order.store_id}").
                            where("current_day = #{work_order.current_day}").order("created_at asc").first
        if another_work_order
          another_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
            :started_at => current_time, :ended_at => ended_at, :station_id => work_order.station_id)
          another_order = another_work_order.order
          another_order.update_attribute(:status, Order::STATUS[:SERVICING]) if another_order
        end
      end
    end
    render :json => {:status => "sort_station_success"}
  end

#  #手机入库
#  def into_materials
#    data = JSON.parse(params[:data])
#    store_id = data["store_id"]
#    materials = data["materials"]
#    mat_arr = []
#    materials.each do |mat|
#      material = Material.where("code = #{mat['code']} and store_id = #{store_id}").first
#      if material
#        material.check_num = mat['check_num'].to_i
#        mat_arr << material
#      else
#        mat_arr << material
#      end
#    end
#    if mat_arr.include?(nil)
#      render :json => {:status => "error", :message => "没有材料"}
#    else
#      if Material.import mat_arr, :on_duplicate_key_update => [:check_num]
#        render :json => {:status => "success"}
#      else
#        render :json => {:status => "error", :message => "更新材料数量失败"}
#      end
#    end
#  end

  #盘点实数
  def check_num
    data = JSON.parse(params[:data])
    store_id = data["store_id"]
    materials = data["materials"]
    mat_arr = []
    materials.each do |mat|
      material = Material.where("code = #{mat['code']} and store_id = #{store_id}").first
      if material
        material.check_num = mat['check_num'].to_i
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

  #出库
  def out_materials
    data = JSON.parse(params[:data])
    store_id = data["store_id"].to_i
    materials = data["materials"]
    staff_id = data["staff_id"].to_i
    mat_out_types = data["mat_out_types"]
    mat_arr = []
    materials.each do |mat|
      material = Material.where("code = #{mat['code']} and store_id = #{store_id}").first
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
      render :json => {:status => "error", :message => "没有材料或者你的盘点数量超过库存数量"}
    else
      Material.transaction do
        begin
          mat_arr.each do |mat|
            mat.save
          end
          render :json => {:status => "success"}
        rescue
          render :json => {:status => "error", :message => "出库失败"}
        end
      end
#      if Material.import mat_arr, :on_duplicate_key_update => [:storage, :check_num, :mat_out_orders]
#        render :json => {:status => "success"}
#      else
#        render :json => {:status => "error", :message => "出库失败"}
#      end
    end
  end

  #员工登录,如果登录成功，返回正在施工中的订单
  def login_and_return_construction_order
    staff = Staff.find_by_username(params[:username])
    if staff.nil? || !staff.has_password?(params[:user_password])
      #用户名或者密码错误
      render :json => {:status => 0}
    else
      #登录成功
      current_day = Time.now.strftime("%Y%m%d")
      orders = Order.includes(:work_orders).where("orders.store_id = #{staff.store_id}").
                     where("orders.status = #{Order::STATUS[:SERVICING]}").
                     where("work_orders.current_day = #{current_day}")

      #所有的code，材料名称
      materials = Material.where("store_id = #{staff.store_id} and status = #{Material::STATUS[:NORMAL]}").select("code, name, storage")
      mat_out_types = MatOutOrder::TYPES
      render :json => {:status => 1, :orders => orders, :store_id => staff.store_id,
        :materials => materials, :staff_id => staff.id, :mat_out_types => mat_out_types}
    end
  end
  
end
