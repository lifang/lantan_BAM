#encoding: utf-8
class CustomersController < ApplicationController
  before_filter :sign?
  include RemotePaginateHelper
  layout "customer"
  before_filter :customer_tips

  def index
    session[:c_types] = nil
    session[:car_num] = nil
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:name] = nil
    session[:phone] = nil
    session[:is_vip] = nil

    @store = @store = Store.find_by_id(params[:store_id]) || not_found
    @customers = Customer.search_customer(params[:c_types], params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone], params[:is_vip], params[:page])
    @car_nums = Customer.customer_car_num(@customers)
  end

  def search
    session[:c_types] = params[:c_types]
    session[:car_num] = params[:car_num]
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:name] = params[:name]
    session[:phone] = params[:phone]
    session[:is_vip] = params[:is_vip]
    redirect_to "/stores/#{params[:store_id]}/customers/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(session[:c_types], session[:car_num], session[:started_at], session[:ended_at],
      session[:name], session[:phone], session[:is_vip], params[:page])
    @car_nums = Customer.customer_car_num(@customers)
    render "index"
  end

  def destroy
    @customer = Customer.find(params[:id].to_i)
    @customer.update_attributes(:status => Customer::STATUS[:DELETED])
    redirect_to request.referer
  end

  def create
    if params[:new_name] and params[:mobilephone]
      customer = Customer.find_by_mobilephone(params[:mobilephone].strip)
      car_num = CarNum.find_by_num(params[:new_car_num].strip)
      if customer
        flash[:notice] = "手机号码#{params[:mobilephone].strip}在系统中已经存在。"
      else
        Customer.create_single_cus(customer, car_num, params[:mobilephone].strip, params[:new_car_num].strip,
          params[:new_name].strip, params[:other_way].strip,
          params[:birthday], params[:buy_year], params[:car_models], params[:sex], params[:address])
        flash[:notice] = "客户信息创建成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def update
    if params[:new_name] and params[:mobilephone]
      customer = Customer.find(params[:id].to_i)
      mobile_c = Customer.find_by_mobilephone(params[:mobilephone].strip)
      if mobile_c and mobile_c.id != customer.id
        flash[:notice] = "手机号码#{params[:mobilephone].strip}在系统中已经存在。"
      else
        customer.update_attributes(:name => params[:new_name].strip, :mobilephone => params[:mobilephone].strip,
          :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
          :address => params[:address])
        flash[:notice] = "客户信息更新成功。"
      end
    end
    redirect_to request.referer
  end

  def customer_mark
    customer = Customer.find(params[:c_customer_id].to_i)
    customer.update_attributes(:mark => params[:mark].strip) if params[:mark]
    flash[:notice] = "备注成功。"
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def single_send_message
    unless params[:content].strip.empty? or params[:m_customer_id].nil?
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => params[:store_id].to_i, :content => params[:content].strip,
          :status => MessageRecord::STATUS[:SENDED], :send_at => Time.now)
        customer = Customer.find(params[:m_customer_id].to_i)
        content = params[:content].strip.gsub("%name%", customer.name)
        SendMessage.create(:message_record_id => message_record.id, :customer_id => customer.id,
          :content => content, :phone => customer.mobilephone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED])
        begin
          message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{customer.mobilephone}&Content=#{content}&Exno=0"
          create_get_http(Constant::MESSAGE_URL, message_route)
        rescue
          flash[:notice] = "短信通道忙碌，请稍后重试。"
        end
        flash[:notice] = "短信发送成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def show
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @car_nums = CarNum.find_by_sql(["select c.id c_id, c.num, cb.name b_name, cm.name m_name, cb.id b_id, cr.customer_id,
        cm.id m_id, c.buy_year,cb.capital_id
        from car_nums c left join car_models cm on cm.id = c.car_model_id
        left join car_brands cb on cb.id = cm.car_brand_id
        inner join customer_num_relations cr on cr.car_num_id = c.id
        where cr.customer_id = ?", @customer.id])
    @orders = Order.one_customer_orders(Order::STATUS[:DELETED], params[:store_id].to_i, @customer.id, 10, params[:page])
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, 10, params[:page])
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, 10, params[:page])
  end

  def order_prods
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @orders = Order.one_customer_orders(Order::STATUS[:DELETED], params[:store_id].to_i, @customer.id, 10, params[:page])
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    respond_to do |format|
      format.js
    end
  end

  def revisits
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, 10, params[:page])
    respond_to do |format|
      format.js
    end
  end

  def complaints
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, 10, params[:page])
    respond_to do |format|
      format.js
    end
  end

  def edit_car_num
    car_num_id = params[:id].split("_")[1].to_i
    customer_id = params[:id].split("_")[0]
    current_car_num = CarNum.find_by_id(car_num_id)
    car_num = CarNum.find_by_num(params["car_num_#{car_num_id}"].strip)
    if car_num.nil? or car_num.id == current_car_num.id
      current_car_num.update_attributes(:num => params["car_num_#{car_num_id}"].strip,
        :buy_year => params["buy_year_#{car_num_id}"].to_i, :car_model_id => params["car_models_#{car_num_id}"].to_i)      
    else
      CustomerNumRelation.delete_all(["car_num_id = ?", car_num.id])
      CustomerNumRelation.create(:car_num_id => car_num.id, :customer_id => customer_id.to_i)
    end
    flash[:notice] = "车牌号码信息修改成功。"
    redirect_to "/stores/#{params["store_id_#{car_num_id}"]}/customers/#{customer_id}"
  end

  def get_car_brands
    respond_to do |format|
      format.json {
        render :json => CarBrand.get_brand_by_capital(params[:capital_id].to_i)
      }
    end
  end

  def get_car_models
    respond_to do |format|
      format.json {
        render :json => CarModel.get_model_by_brand(params[:brand_id].to_i)
      }
    end
  end

  def check_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    respond_to do |format|
      format.json {
        render :json => {:is_has => car_num.nil?}
      }
    end
  end

  def check_e_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    is_has = (car_num.nil? or (!car_num.nil? and (car_num.id == params[:car_num_id].to_i))) ? true : false
    respond_to do |format|
      format.json {
        render :json => {:is_has => is_has}
      }
    end
  end

  def delete_car_num
    ids = params[:id].split("_")
    customer_num_relation = CustomerNumRelation.find_by_car_num_id_and_customer_id(ids[0], ids[1])
    customer_num_relation.destroy
    flash[:notice] = "删除成功。"
    redirect_to request.referer
  end

end
