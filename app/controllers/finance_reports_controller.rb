#encoding: utf-8
class FinanceReportsController < ApplicationController
  layout 'finance'
  require 'will_paginate/array'
  
  def index
    @title = "主营收入"
    @category = Category.where(:store_id=>params[:store_id],:types=>Category::DATA_TYPES).inject({}){|h,c|h[c.id]=c.name;h}
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql,orders,del_ids = "1=1",[],[]
    if @start_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    if params[:customer_name]
      sql += " and customers.name like '%#{params[:customer_name].gsub(/[%_]/){|x| '\\' + x}}%'"
    end
    if params[:category_id]
      sql += " and products.category_id=#{params[:category_id]}"
      p_orders = Order.joins([:car_num,:customer,:order_prod_relations =>:product]).select("orders.*,customers.mobilephone phone,
     customers.name c_name,customers.group_name,car_nums.num c_num,customers.id c_id").where(:status=>Order::OVER_CASH,:store_id=>
          params[:store_id]).where(sql).order("orders.updated_at desc")
    else
      p_orders = Order.joins([:car_num,:customer]).select("orders.*,customers.mobilephone phone,customers.name c_name,customers.group_name,
     car_nums.num c_num,customers.id c_id").where(:status=>Order::OVER_CASH,:store_id=>params[:store_id]).where(sql).order("orders.updated_at desc")
      del_ids = CSvcRelation.joins(:sv_card).where(:"sv_cards.types"=>SvCard::FAVOR[:SAVE],:"sv_cards.store_id"=>params[:store_id]).map(&:order_id)
      del_ids << CPcardRelation.joins(:package_card).where(:"package_cards.store_id"=>params[:store_id]).map(&:order_id)
    end
    p_types = params[:pay_type].nil? ? OrderPayType::FINCANCE_TYPES.keys : params[:pay_type].split(",").inject([]){|arr,type|arr << type.to_i}
    order_types = OrderPayType.pay_order_types(p_orders.map(&:id))
    p_orders.each do |p_order|
      if order_types[p_order.id]
        o_types = order_types[p_order.id].keys
        orders <<  p_order if (o_types-p_types).length != o_types.length and !del_ids.flatten.include? p_order.id
      end
    end
    unless orders.blank?
      @pays = OrderPayType.search_pay_types(orders.map(&:id))
      @orders = orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
      @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
      @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
      staff_ids = (@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id)).compact.uniq
      staff_ids.delete 0
      @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    else
      @pays,@orders = {},[]
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def revenue_report
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "1=1"
    if @start_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    @p_orders = Order.joins([:car_num,:customer,:order_prod_relations=>:product]).joins("left join work_orders w on w.order_id=orders.id").
      select("orders.*,customers.mobilephone phone,customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,
      customers.id c_id,products.is_service").where(:status=>Order::PRINT_CASH,:store_id=>params[:store_id]).where(sql).order("orders.updated_at desc")
    @pays = OrderPayType.search_pay_types(@p_orders.map(&:id))
    @pay_types = OrderPayType.pay_order_types(@p_orders.map(&:id))
    @order_price = @p_orders.inject({}){|h,p|h[p.is_service].nil? ? h[p.is_service]={p.id=>p.price} : h[p.is_service][p.id]=p.price;h}
    @orders = @p_orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def fee_manage
    
  end

end
