#encoding: utf-8
class Api::OrdersController < ApplicationController
  #首页
  def index_list
    status = 0
    begin
      @reservations = Reservation.store_reservations params[:store_id]
      @orders = Order.working_orders Order::STATUS[:SERVICING], params[:store_id]
      status = 1
    rescue
      status = 2
    end
    render :json => {:status => status,:orders => @orders,:reservations => @reservations}.to_json
  end

  def login
    @staff = Staff.find_by_username(params[:user_name])
    info = ""
    if  @staff.nil? or !@staff.has_password?(params[:user_password])
      info = "用户名或密码错误"
    elsif @staff.status != Staff::STATUS[:normal]
      info = "用户不存在"
    else
      cookies[:user_id]={:value => @staff.id, :path => "/", :secure  => false}
      cookies[:user_name]={:value =>@staff.name, :path => "/", :secure  => false}
      session_role(cookies[:user_id])
      if is_admin? or is_boss? or is_manager? or is_staff?
        info = ""
      else
        cookies.delete(:user_id)
        cookies.delete(:user_name)
        cookies.delete(:user_roles)
        cookies.delete(:model_role)
        info = "抱歉，您没有访问权限"
      end
    end
    render :json => {:staff => @staff, :info => info}.to_json
  end
  #根据车牌号查询客户
  def search_car
    order = Order.search_by_car_num params[:store_id],params[:car_num]
    result = {:status => 1,:customer => order[0],:working => order[1], :old => order[2] }.to_json
    puts result
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
    #puts str,order,info
    render :json => {:status => order[0], :content => str, :order => info}
  end
  #付款
  def pay
    order = Order.pay params[:order_id],params[:store_id],params[:please],params[:pay_type],params[:billing],params[:code]
    content = ""
    if order[0] == 0
      content = ""
    elsif order[0] == 1
      content = "success"
    elsif order[0] == 2
      content = "订单不存在"
    elsif order[0] = 3
      content = "储值卡余额不足，请选择其他支付方式"
    end
    render :json => {:status => order[0], :content => content}
  end
  #投诉
  def complaint
    complaint = Complaint.mk_record params[:store_id],params[:order_id],params[:reason],params[:request]
    render :json => {:status => (complaint.nil? ? 0 : 1)}
  end

  def brands_products
    items = Order.get_brands_products params[:store_id]
    render :json => {:status => 1, :brands => items[0], :products => items[1], :count => items[1][4]}
  end

  def finish
    prod_id = params[:prod_ids]
    prod_id = prod_id[0...(prod_id.size-1)] if prod_id
    pre_arr = Order.pre_order params[:store_id],params[:carNum],params[:brand],params[:year],params[:userName],params[:phone],
                    params[:email],params[:birth],prod_id
    content = ""
    if pre_arr[5] == 0
      content = "数据出现异常"
    elsif pre_arr[5] == 1
      content = "success"
    elsif pre_arr[5] == 2
      content = "选择的产品和服务无法匹配工位"
    end
    render :json => {:status => pre_arr[5],:info => pre_arr[0], :products => pre_arr[1], :sales => pre_arr[2],
                     :svcards => pre_arr[3], :pcards => pre_arr[4], :total => pre_arr[6], :content  => content}
  end

  def confirm_reservation
    reservation = Reservation.find_by_id_and_store_id params[:r_id].to_i,params[:store_id]

    if reservation && reservation.status == Reservation::STATUS[:normal]
      reservation.update_attribute(:status, Reservation::STATUS[:confirmed]) if params[:status].to_i == 0
      reservation.update_attribute(:status, Reservation::STATUS[:cancel]) if params[:status].to_i == 1
    end
    reservations = Reservation.store_reservations params[:store_id]
    render :json => {:status => 1, :reservation => reservations}
  end

  def refresh
    reservations = Reservation.store_reservations params[:store_id]
    render :json => {:status => 1, :reservation => reservations }
  end
end
