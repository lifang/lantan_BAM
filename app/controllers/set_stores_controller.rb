#encoding: utf-8
class SetStoresController < ApplicationController
  layout "role"
  before_filter :sign?, :except => [:update]
  require 'will_paginate/array'
  
  def index
    @store = Store.find_by_id(params[:store_id].to_i)
    @store_city = City.find_by_id(@store.city_id) if @store.city_id
    @cities = City.where(["parent_id = ?", @store_city.parent_id]) if @store_city
    @province = City.where(["parent_id = ?", City::IS_PROVINCE])
  end

  def update
    store = Store.find_by_id(params[:id].to_i)
    update_sql = {:name => params[:store_name].strip, :address => params[:store_address].strip, :phone => params[:store_phone].strip,
      :contact => params[:store_contact].strip, :position => params[:store_position_x]+","+params[:store_position_y],
      :opened_at => params[:store_opened_at], :status => params[:store_status].to_i, :city_id => params[:store_city].to_i }
    if store.update_attributes(update_sql)
      if !params[:store_img].nil?
        begin
          url = Store.upload_img(params[:store_img], store.id, Constant::STORE_PICS, Constant::STORE_PICSIZE)
          store.update_attribute("img_url", url)
        rescue
          flash[:notice] = "图片上传失败!"
        end
      end
      cookies.delete(:store_name) if cookies[:store_name]
      cookies[:store_name] = {:value => store.name, :path => "/", :secure => false}
      flash[:notice] = "设置成功!"
    else
      flash[:notice] = "更新失败!"
    end
    redirect_to store_set_stores_path
  end

  def select_cities   #选择省份时加载下面的所有城市
    p_id = params[:p_id]
    @cities = City.where(["parent_id = ?", p_id])
  end


  def cash_register
    about_cash(params[:store_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def complete_pay
    start_time = params[:first].nil? || params[:first] == "" ? Time.now.at_beginning_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:first]}"
    end_time = params[:last].nil? || params[:last] == "" ? Time.now.end_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:last]}"
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,
      customers.mobilephone phone,customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,customers.id c_id").
      where(:status=>Order::OVER_CASH,:store_id=>params[:store_id]).where("date_format(orders.created_at,'%Y-%m-%d %H:%i')>='#{start_time}' and
      date_format(orders.created_at,'%Y-%m-%d %H:%i')<='#{end_time}'").order("orders.created_at desc")
    @pays = OrderPayType.where(:order_id=>orders.map(&:id)).select("sum(price) total_price,pay_type").group("pay_type").inject(Hash.new){
      |hash,pay|hash[pay.pay_type] = pay.total_price;hash}
    @orders = orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @pay_types = OrderPayType.order_pay_types(@orders.map(&:id))
    @staffs = Staff.find((@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id))).inject(Hash.new){|hash,staff|
      hash[staff.id]=staff.name;hash}
    @stations = Station.find(@orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def about_cash(store_id)
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,customers.mobilephone,
   customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,customers.id c_id").where(:status=>Order::CASH,
      :store_id=>store_id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(orders.map(&:id))
    @orders = orders.group_by{|i|{:c_name=>i.c_name,:c_num=>i.c_num,:tel=>i.mobilephone,:g_name=>i.group_name,:c_id=>i.c_id} }
    @staffs = Staff.find((orders.map(&:cons_staff_id_1)|orders.map(&:cons_staff_id_2)|orders.map(&:front_staff_id))).inject(Hash.new){|hash,staff|
      hash[staff.id]=staff.name;hash}
    @stations =Station.find(orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def load_order
    @customer = Customer.find params[:customer_id]
    @orders = Order.joins([:car_num]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,car_nums.num c_num,
    w.station_id s_id").where(:status=>Order::CASH,
      :store_id=>params[:store_id],:customer_id=>params[:customer_id]).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
  end

end