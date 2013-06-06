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
    elsif !Staff::VALID_STATUS.include?(staff.status)
      info = "用户不存在"
    else
      cookies[:user_id]={:value => staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>staff.name, :path => "/", :secure  => false}
      session_role(cookies[:user_id])
      if has_authority?
        info = ""
      else
        cookies.delete(:user_id)
        cookies.delete(:user_name)
        cookies.delete(:user_roles)
        cookies.delete(:model_role)
        info = "抱歉，您没有访问权限"
      end
    end
    render :json => {:staff => staff, :info => info}.to_json
  end
  #根据车牌号查询客户
  def search_car
    order = Order.search_by_car_num params[:store_id],params[:car_num], nil
    result = {:status => 1,:customer => order[0],:working => order[1], :old => order[2] }.to_json
    render :json => result
  end

  #查看订单
  def show_car
    order = Order.search_by_car_num params[:store_id],params[:car_num], params[:car_id]
    result = {:status => 1,:customer => order[0],:working => order[1], :old => order[2] }.to_json
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
      params[:pay_type], params[:billing], params[:code], params[:is_free])
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
    render :json => {:status => 1, :brands => items[0], :products => items[1], :count => items[1][4]}
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

  #查询订单后的支付
  def pay_order
    order = Order.find_by_id params[:order_id]
    status = 0
    if params[:opt_type].to_i == 1
      if order && order.status == Order::STATUS[:NORMAL]
        oprs = OPcardRelation.find_all_by_order_id(order.id)
        oprs.each do |opr|
          cpr = CPcardRelation.find(opr.c_pcard_relation_id)
          pns = cpr.content.split(",").map{|pn| pn.split("-")} if cpr
          pns.each do |pn|
            pn[2] = pn[2].to_i + opr.product_num if pn[0].to_i == opr.product_id
          end if pns
          cpr.update_attribute(:content,pns.map{|pn| pn.join("-")}.join(",")) if cpr
        end unless oprs.blank?
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
      begin
        #同步客户信息
        customers_info = sync_info["customer"]
        customers_info.each do |customer|
          old_customer = Customer.find_by_mobilephone(customer["phone"])
          old_customer.update_attributes(:name => customer["name"].strip, :other_way => customer["email"],
            :birthday => customer["birth"], :sex => customer["sex"]) if old_customer
          carNum = CarNum.find_by_num(customer["carNum"])
          Customer.create_single_cus(old_customer, carNum, customer["phone"], customer["carNum"], customer["name"],
            customer["email"], customer["birth"], customer["year"], customer["brand"].split("_")[1].to_i, customer["sex"], nil)
        end

        #同步订单信息
        orders_info = sync_info["order"]
        orders_info.each do |order_info|
          carNum = CarNum.find_by_num(order_info["carNum"])

          customer_id = carNum.customer_num_relation.customer.id

          order = Order.new(:is_billing => order_info["billing"], :created_at => order_info["time"], :store_id => order_info["store_id"],
                            :price => order_info["price"], :front_staff_id => order_info["user_id"], :is_pleased => order_info["is_please"],
                            :status => order_info["status"], :code => MaterialOrder.material_order_code(order_info["store_id"].to_i, order_info["time"]),
                            :car_num_id => carNum.try(:id), :customer_id => customer_id)
          order.order_pay_types.new(:pay_type => order_info["pay_type"], :price => order_info["price"], :created_at => order_info["time"])
          order.complaints.new(:reason => order_info["complaint"]["reason"], :suggestion => order_info["complaint"]["request"], :created_at => order_info["time"]) if order_info.keys.include?("complaint")

          prod_arr = Order.get_prod_sale_card(order_info["prods"])
          (prod_arr[0] || []).each do |prod|
            product = Product.find_by_id_and_store_id_and_status(prod[1].to_i,order_info["store_id"],Product::IS_VALIDATE[:YES])
            if product
              order.order_prod_relations.new(:product_id => product.id, :pro_num => prod[2], :total_price => prod[3], :price => product.sale_price, :t_price => product.t_price, :created_at => order_info["time"])
            end
          end

          (prod_arr[3] || []).each do |pcard|
            package_card = PackageCard.find_by_id(pcard[1])
            if order_info["status"] == Order::STATUS[:BEEN_PAYMENT]
              order.c_pcard_relations.new(:customer_id => customer_id, :package_card_id => pcard[1], :status => CPcardRelation::STATUS[:NORMAL], :price => package_card.try(:price), :created_at => order_info["time"])
            else
              order.c_pcard_relations.new(:customer_id => customer_id, :package_card_id => pcard[1], :status => CPcardRelation::STATUS[:INVALID], :price => package_card.try(:price), :created_at => order_info["time"])
            end
          end
          order.save
        end
      rescue
        flag = false
      end
    end
    resp_text = flag ? "success" : "error"
    render :json => {:status => resp_text}
  end
end
