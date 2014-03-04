#encoding: utf-8
class DataManagesController < ApplicationController
  include MarketManagesHelper
  before_filter :sign?
  layout "complaint", :except => []
  require 'will_paginate/array'

  def index
    @t_orders = []
    session[:date] = params[:date].nil? ? Time.now.strftime("%Y-%m") : params[:date]
    orders = OrderPayType.joins(:order=>{:order_prod_relations=>{:product=>:category}}).select(
      "round(ifnull(sum(order_pay_types.price),0),2) sum_price,pay_type,categories.types,pay_type,products.category_id,orders.id o_id").where(
      :"orders.store_id"=>params[:store_id],:"orders.status"=>Order::PRINT_CASH).where(
      "date_format(orders.created_at,'%Y-%m')='#{session[:date]}'").group("pay_type,products.category_id,o_id").group_by{
      |i|{:pay_type=>i.pay_type,:ca=>i.category_id}}
    @favour = orders.select{|k,v| OrderPayType::FAVOUR.include? k[:pay_type] }.values.flatten.inject({}){
      |h,fav| h[fav.category_id].nil? ? h[fav.category_id]=fav.sum_price : h[fav.category_id] +=fav.sum_price;h}
    @prod_service = orders.select{|k,v| !OrderPayType::FAVOUR.include? k[:pay_type] }.values.flatten.inject({}){
      |h,p|@t_orders << p.o_id;h[p.types].nil? ? h[p.types]={p.category_id=>p.sum_price} : h[p.types][p.category_id].nil? ? h[p.types][p.category_id]=p.sum_price : h[p.types][p.category_id] +=p.sum_price;h}
    @category = Category.where(:store_id=>params[:store_id],:types=>Category::DATA_TYPES).inject({}){|h,c|h[c.types].nil? ? h[c.types]={c.id=>c.name} : h[c.types][c.id]=c.name;h}
    @favour_cat = @category.values.flatten.inject({}){|h,v|h.merge!(v)}
    p @t_price = Order.joins(:order_prod_relations=>{:product=>:category}).select("sum(order_prod_relations.t_price) sum_t,
      categories.types,products.category_id").group("categories.types,products.category_id").where(:"orders.id"=>@t_orders.compact.uniq,
      :"order_prod_relations.return_types"=>Order::IS_RETURN[:NO]).inject({}){|h,o|h[o.types].nil? ? h[o.types]={o.category_id=>o.sum_t} : h[o.types][o.category_id]=o.sum_t;h} #计算成本价
    @total_t_price = @t_price.values.flatten.inject({}){|h,v|h.merge!(v)}.values.compact.inject(0){|sum,t|sum+t}.round(2)
    @total_price = @prod_service.values.flatten.inject({}){|h,v|h.merge!(v)}.values.compact.inject(0){|sum,t|sum+t}.round(2)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def ajax_prod_serv
    category_id = params[:category_id].to_i
    sql = "date_format(orders.created_at,'%Y-%m')='#{params[:c_time]}'"
    if params[:c_types].to_i == 0 or params[:c_types].to_i == 3
      sql += " and category_id=#{category_id}"
    elsif params[:c_types].to_i == 1 or params[:c_types].to_i == 2
      sql += " and categories.types=#{category_id}"
    end
    if params[:c_types].to_i < 3
      @c_name = params[:c_types].to_i == 0 ? Category.find(category_id).name : Category::TYPES_NAME[category_id]
      p @orders = Order.joins(:order_prod_relations=>{:product=>:category}).select("ifnull(sum(order_prod_relations.pro_num),0) pro_num,
    ifnull(sum(order_prod_relations.total_price),0) total_price,round(ifnull(sum(order_prod_relations.t_price),0),2) t_price,products.id p_id,
    date_format(orders.created_at,'%Y-%m-%d') day,ifnull(sum(order_prod_relations.total_price-order_prod_relations.t_price),0) earn_price,
    products.service_code,products.name").where(:"orders.store_id"=>params[:store_id],:"orders.status"=>Order::PRINT_CASH).where(sql).group("p_id,day").group_by{|i|i.day}
    else
      @c_name = params[:c_types].to_i == 3 ? Category.find(category_id).name : "折扣优惠"
      p @orders = OrderPayType.joins({:product=>:category},:order).select("'--' pro_num,ifnull(sum(order_pay_types.price),0) total_price,
    date_format(orders.created_at,'%Y-%m-%d') day,'--' t_price,products.id p_id,ifnull(sum(order_pay_types.price),0) earn_price,
    products.service_code,products.name").where(:"orders.store_id"=>params[:store_id],:"orders.status"=>Order::PRINT_CASH,
        :"pay_type"=>OrderPayType::FAVOUR).where(sql).group("p_id,day").group_by{|i|i.day}
    end
  end
end
