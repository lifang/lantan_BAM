#encoding: utf-8
class SetStoresController < ApplicationController
  layout "role" ,:except =>["print_paper","single_print"]
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
      :opened_at => params[:store_opened_at], :status => params[:store_status].to_i, :city_id => params[:store_city].to_i,
      :cash_auth => params[:store_cash_auth].to_i}
    update_sql.merge!(:limited_password=>Digest::MD5.hexdigest(params[:limited_password])) if permission?(:pay_cash, :can_pay) && params[:limited_password]!=""
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
    @title = "收银"
    about_cash(params[:store_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def complete_pay
    @title = "收银"
    start_time = params[:first].nil? || params[:first] == "" ? Time.now.at_beginning_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:first]}"
    end_time = params[:last].nil? || params[:last] == "" ? Time.now.end_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:last]}"
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,
      customers.mobilephone phone,customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,customers.id c_id").
      where(:status=>Order::OVER_CASH,:store_id=>params[:store_id]).where("date_format(orders.updated_at,'%Y-%m-%d %H:%i')>='#{start_time}' and
      date_format(orders.updated_at,'%Y-%m-%d %H:%i')<='#{end_time}'").order("orders.updated_at desc")
    @pays = OrderPayType.where(:order_id=>orders.map(&:id)).select("sum(price) total_price,pay_type").group("pay_type").inject(Hash.new){
      |hash,pay|hash[pay.pay_type] = pay.total_price;hash}
    @orders = orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    staff_ids = (@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @stations = Station.find(@orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def about_cash(store_id)
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,customers.mobilephone,
   customers.name c_name,customers.group_name,car_nums.num c_num,car_nums.id n_id,w.station_id s_id,customers.id c_id").where(:status=>Order::CASH,
      :store_id=>store_id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(orders.map(&:id))
    @orders = orders.group_by{|i|{:c_name=>i.c_name,:c_num=>i.c_num,:tel=>i.mobilephone,:g_name=>i.group_name,:c_id=>i.c_id,:n_id=>i.n_id} }
    @order_pays = OrderPayType.search_pay_order(orders.map(&:id))
    staff_ids = (orders.map(&:cons_staff_id_1)|orders.map(&:cons_staff_id_2)|orders.map(&:front_staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @stations = Station.find(orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def load_order
    @customer = Customer.find params[:customer_id]
    @car_num = CarNum.find params[:car_num_id]
    @orders = Order.select("orders.*").where(:status=>Order::CASH,:store_id=>params[:store_id],:customer_id=>params[:customer_id],
      :car_num_id=>@car_num.id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    prod_ids = OrderProdRelation.joins(:product).where(:order_id=>@orders.map(&:id)).select("products.category_id").map(&:category_id)
    @cates = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good], Category::TYPES[:service]]).inject(Hash.new){|hash,c|
      hash[c.id]=c.name;hash}
    @sv_card = []
    unless prod_ids.blank?
      sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:customer_id=>@customer.id,:"sv_cards.types" => SvCard::FAVOR[:SAVE]).where("
      c_svc_relations.status=#{CSvcRelation::STATUS[:valid]} or order_id in (#{@orders.map(&:id).join(',')})").select("c_svc_relations.*,sv_cards.name,
      sv_cards.store_id,svcard_prod_relations.category_id ci,c_svc_relations.status sa,order_id o_id").where("sv_cards.store_id=#{params[:store_id]}")
      sv_cards.each do |sv|
        prod_ids.each do |ca|
          if sv.ci  and sv.ci.split(",").include? "#{ca}"
            @sv_card  << sv
            break
          end
        end
      end
    end
    @order_pays = OrderPayType.search_pay_order(@orders.map(&:id))
  end

  def pay_order
    @may_pay = OrderPayType.deal_order(request.parameters)
    about_cash(params[:store_id])  if @may_pay[0]
  end

  def print_paper
    @store = Store.find params[:store_id]
    @customer = Customer.find params[:c_id]
    @car_num = CarNum.find params[:n_id]
    @orders = Order.where(:id=>params[:o_id].split(',').compact.uniq)
    staff_ids = (@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @order_pays = OrderPayType.search_pay_types(@orders.map(&:id))
    if @order_pays.keys.include? OrderPayType::PAY_TYPES[:CASH]
      @cash_pay =OrderPayType.where(:order_id=>@orders.map(&:id),:pay_type=>OrderPayType::PAY_TYPES[:CASH]).first
    end
  end

  def single_print
    @store = Store.find params[:store_id]
    @orders = Order.where(:store_id=>params[:store_id],:id=>params[:order_id])
    order = @orders.first
    @customer = Customer.find order.customer_id
    @car_num = CarNum.find order.car_num_id
    staff_ids = [order.cons_staff_id_1,order.cons_staff_id_2,order.front_staff_id].compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @order_prods = OrderProdRelation.order_products(order.id)
    @order_pays = OrderPayType.search_pay_types(order.id)
    if @order_pays.keys.include? OrderPayType::PAY_TYPES[:CASH]
      @cash_pay =OrderPayType.where(:order_id=>@orders.map(&:id),:pay_type=>OrderPayType::PAY_TYPES[:CASH]).first
    end
  end

end