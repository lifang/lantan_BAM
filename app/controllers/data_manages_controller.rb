#encoding: utf-8
class DataManagesController < ApplicationController
  include MarketManagesHelper
  before_filter :sign?
  layout "complaint", :except => []
  require 'will_paginate/array'

  def index
    t_orders = []
    session[:date] = params[:date].nil? ? Time.now.strftime("%Y-%m") : params[:date]
    orders = OrderPayType.joins(:order=>{:order_prod_relations=>{:product=>:category}}).select(
      "ifnull(sum(order_pay_types.price),0) sum_price,pay_type,categories.types,pay_type,products.category_id,orders.id o_id").where(
      :"orders.store_id"=>params[:store_id],:"orders.status"=>Order::PRINT_CASH).where(
      "date_format(orders.created_at,'%Y-%m')='#{session[:date]}'").group("pay_type,products.category_id,o_id").group_by{
      |i|{:pay_type=>i.pay_type,:ca=>i.category_id}}
    p @favour = orders.select{|k,v| OrderPayType::FAVOUR.include? k[:pay_type] }.values.flatten.inject({}){
      |h,fav| h[fav.category_id].nil? ? h[fav.category_id]=fav.sum_price : h[fav.category_id] +=fav.sum_price;h}
    p @prod_service = orders.select{|k,v| !OrderPayType::FAVOUR.include? k[:pay_type] }.values.flatten.inject({}){
      |h,p|t_orders << p.o_id;h[p.types].nil? ? h[p.types]={p.category_id=>p.sum_price} : h[p.types][p.category_id].nil? ? h[p.types][p.category_id]=p.sum_price : h[p.types][p.category_id] +=p.sum_price;h}
    @category = Category.where(:store_id=>params[:store_id]).inject({}){|h,c|h[c.id]=c.name;h}
    p @t_price = Order.joins(:order_prod_relations=>{:product=>:category}).select("sum(order_prod_relations.t_price*order_prod_relations.pro_num) sum_t,
      categories.types,products.category_id").group("categories.types,products.category_id").where(:"orders.id"=>t_orders.compact.uniq,
      :"order_prod_relations.return_type"=>Order::IS_RETURN[:YES]).inject({}){|h,o|h["#{o.types}_#{o.category_id}"]=o.sum_t;h} #计算成本价
  end

end
