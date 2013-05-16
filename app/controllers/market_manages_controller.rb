#encoding: utf-8
class MarketManagesController < ApplicationController
  before_filter :sign?
  layout "complaint", :except => [:daily_consumption_receipt_blank, :stored_card_bill_blank]
  require 'will_paginate/array'

  before_filter :get_store, :only => [:stored_card_record, :daily_consumption_receipt, :stored_card_bill]

  #营业额汇总表
  def makets_totals
    session[:created],session[:ended]=nil,nil
    @month_goal =MonthScore.sort_order(params[:store_id])
    @months =@month_goal.inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : hash[order.day].merge!(order.pay_type=>order.price);hash }
    @total_num = @month_goal.inject(0){|num,order| num + order.price}
    p @months
  end

  #营业额汇总查询
  def search_month
    session[:created],session[:ended]=nil,nil
    session[:created],session[:ended]=params[:created],params[:ended]
    redirect_to "/stores/#{params[:store_id]}/market_manages/makets_list"
  end

  #营业额汇总查询列表
  def makets_list
    @month_goal =MonthScore.sort_order_date(params[:store_id],session[:created],session[:ended])
    @months =@month_goal.inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : hash[order.day].merge!(order.pay_type=>order.price);hash }
    @total_num =@month_goal.inject(0){|num,order| num+order.price}
    render 'makets_totals'
  end

  #销售报表
  def makets_reports
    session[:r_created],session[:r_ended],session[:time]=nil,nil,nil
    @total_prod,@total_serv,@total_fee =0,0,0
    reports =MonthScore.kind_order(params[:store_id]).inject(Hash.new){
      |hash,prod| hash[prod.is_service].nil? ? hash[prod.is_service]= [prod] : hash[prod.is_service] << prod ;hash
    }
    @prods =reports[Product::PROD_TYPES[:PRODUCT]].inject(Hash.new){
      |hash,prod| @total_prod += prod.sum;hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    } unless reports[Product::PROD_TYPES[:PRODUCT]].nil?
    @serv =reports[Product::PROD_TYPES[:SERVICE]].inject(Hash.new){
      |hash,prod| @total_serv += prod.sum;hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    } unless reports[Product::PROD_TYPES[:SERVICE]].nil?
    @pcards =MonthScore.sort_pcard(params[:store_id]).inject(Hash.new){
      |hash,prod| @total_fee += prod.sum;hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    }
  end

  #销售报表查询
  def search_report
    session[:r_created],session[:r_ended],session[:time]=nil,nil,nil
    session[:r_created],session[:r_ended],session[:time]=params[:created],params[:ended],params[:time].to_i
    redirect_to "/stores/#{params[:store_id]}/market_manages/makets_views"
  end

  #销售报表查询列表
  def makets_views
    @total_prod,@total_serv,@total_fee =0,0,0
    reports =MonthScore.search_kind_order(params[:store_id],session[:r_created],session[:r_ended],session[:time]).inject(Hash.new){
      |hash,prod| hash[prod.is_service].nil? ? hash[prod.is_service]= [prod] : hash[prod.is_service] << prod ;hash
    }
    @prods =reports[Product::PROD_TYPES[:PRODUCT]].inject(Hash.new){
      |hash,prod| @total_prod += prod.sum;hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    } unless reports[Product::PROD_TYPES[:PRODUCT]].nil?
    @serv =reports[Product::PROD_TYPES[:SERVICE]].inject(Hash.new){
      |hash,prod| @total_serv += prod.sum;hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    } unless reports[Product::PROD_TYPES[:SERVICE]].nil?
    @pcards =MonthScore.search_sort_pcard(params[:store_id],session[:r_created],session[:r_ended],session[:time]).inject(Hash.new){
      |hash,prod| @total_fee += prod.sum;hash[prod.day].nil? ? hash[prod.day]= [prod] : hash[prod.day] << prod ;hash
    }
    render 'makets_reports'
  end

  #目标销售额
  def index
    goals =GoalSale.where("store_id=#{params[:store_id]}").inject(Hash.new){|hash,sale|
      hash[sale.ended_at.strftime("%Y-%m-%d")].nil? ? hash[sale.ended_at.strftime("%Y-%m-%d")]=[sale] : hash[sale.ended_at.strftime("%Y-%m-%d")] << [sale];hash }
    @goal_hash =GoalSale.total_type(params[:store_id]).inject(Hash.new){|hash,goal|
      hash[goal.goal_sale_id].nil? ? hash[goal.goal_sale_id]=[goal] : hash[goal.goal_sale_id] << goal;hash }
    @new_goals =goals.select {|key,value| key >= Time.now.strftime("%Y-%m-%d")}.values.flatten
    @old_goals =goals.select {|key,value| key < Time.now.strftime("%Y-%m-%d")}.values.flatten
  end

  #创建目标销售额
  def create
    parms = {:started_at=>params[:created],:ended_at=>params[:ended],:store_id=>params[:store_id],:created_at=>Time.now.strftime("%Y-%m-%d")}
    goal=GoalSale.create(parms)
    parm_type ={:goal_sale_id=>goal.id}
    max_type = GoalSale.max_type(params[:store_id])
    index =1
    params[:goal].each do |k,v|
      type_name=MonthScore::GOAL_NAME[k.to_i].nil? ? params[:val][k] : MonthScore::GOAL_NAME[k.to_i]
      types= MonthScore::GOAL_NAME[k.to_i].nil? ?  (max_type.max.nil? ? GoalSale::TYPES_NAMES.keys.max : max_type.max)+index : k
      unless type_name==""
        parm_type.merge!(:type_name=>type_name,:goal_price=>v,:types=>types)
        GoalSaleType.create(parm_type)
        index +=1 if k.to_i >=4
      end
    end
    redirect_to "/stores/#{params[:store_id]}/market_manages/"
  end

  #活动订单显示
  def sale_orders
    session[:o_created],session[:o_ended],session[:order_name]=nil,nil,nil
    orders = Sale.count_sale_orders(params[:store_id])
    p orders
    @sale_orders =  orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    unless @sale_orders.blank?
      @hash_favor = OrderPayType.find_by_sql("select p.price,o.sale_id,p.pay_type from orders o inner join order_pay_types
     p on p.order_id=o.id where o.sale_id in (#{@sale_orders.map(&:id).join(',')}) ").inject(Hash.new)  {|hash,order_pay|
        hash[order_pay.sale_id].nil? ? hash[order_pay.sale_id]=order_pay.price : hash[order_pay.sale_id] += order_pay.price  if order_pay.pay_type == OrderPayType::PAY_TYPES[:SALE];hash }
      @sale_names =orders.map(&:name)
    end
  end

  def search_sale_order
    session[:o_created],session[:o_ended],session[:order_name]=nil,nil,nil
    session[:o_created],session[:o_ended],session[:order_name]=params[:o_created],params[:o_ended],params[:order_name]
    redirect_to "/stores/#{params[:store_id]}/market_manages/sale_order_list"
  end

  def sale_order_list
    orders = Sale.count_sale_orders_search(params[:store_id],session[:o_created],session[:o_ended],session[:order_name])
    @sale_orders =  orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    unless @sale_orders.blank?
      @hash_favor = OrderPayType.find_by_sql("select p.price,o.sale_id,p.pay_type from orders o inner join order_pay_types
     p on p.order_id=o.id where o.sale_id in (#{@sale_orders.map(&:id).join(',')}) ").inject(Hash.new)  {|hash,order_pay|
        hash[order_pay.sale_id].nil? ? hash[order_pay.sale_id]=order_pay.price : hash[order_pay.sale_id] += order_pay.price  if order_pay.pay_type == OrderPayType::PAY_TYPES[:SALE];hash }
    end
    @sale_names =Sale.count_sale_orders_search(params[:store_id]).map(&:name)
    render 'sale_orders'
  end

  def stored_card_record
    @start_at, @end_at = params[:started_at], params[:ended_at]
    started_at_sql = (@start_at.nil? || @start_at.empty?) ? '1 = 1' : "o.started_at >= '#{@start_at}'"
    ended_at_sql = (@end_at.nil? || @end_at.empty?) ? '1 = 1' : "o.ended_at <= '#{@end_at} 23:59:59'"

    order_details = Order.find_by_sql("select o.id,o.code,opt.price price,opt.created_at created_at,p.name product_name from orders o
                                inner join order_pay_types opt on opt.order_id = o.id inner join order_prod_relations op on
                                op.order_id = o.id inner join products p on op.product_id = p.id
                                where opt.pay_type=#{OrderPayType::PAY_TYPES[:SV_CARD]} and
                                #{started_at_sql} and #{ended_at_sql}")
    
    orders = {}
    order_details.each do |order|
      orders.keys.include?(order.id) ? orders[order.id][:product_name] += (","+order.product_name) : orders[order.id] = order
    end
    @orders = orders.values
    @total_price = @orders.sum(&:price)
  end

  def daily_consumption_receipt
    @search_time = params[:search_time] || Time.now.strftime("%Y-%m-%d")
    
    @current_day_total = Order.where("created_at <= '#{Time.now}'").
      where("created_at >= '#{Time.now.strftime("%Y-%m-%d")}'").sum(:price)

    @orders = Order.where("created_at <= '#{@search_time} 23:59:59'").
      where("created_at >= '#{@search_time} 00:00:00'")
    @search_total = @orders.sum(:price)
  end

  def daily_consumption_receipt_blank
    @search_time = params[:search_time]
    @orders = Order.where("created_at <= '#{@search_time} 23:59:59'").
      where("created_at >= '#{@search_time} 00:00:00'")
    @search_total = @orders.sum(:price)
  end

  def stored_card_bill
    @start_at, @end_at = params[:started_at], params[:ended_at]
    @svc_returns = shared_stored_card_bill(@start_at, @start_at, @store.id)
  end

  def stored_card_bill_blank
    @svc_returns = shared_stored_card_bill(params[:started_at], params[:ended_at], params[:store_id])
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def shared_stored_card_bill(started_at, ended_at, store_id)
    started_at_sql = (started_at.nil? || started_at.empty?) ? '1 = 1' : "srr.created_at >= '#{started_at}'"
    ended_at_sql = (ended_at.nil? || ended_at.empty?) ? '1 = 1' : "srr.created_at <= '#{ended_at} 23:59:59'"

    relation_order_sql = "select srr.*,o.code code,o.id o_id from svc_return_records srr
                          left join orders o on o.id = srr.target_id where #{started_at_sql}
                          and #{ended_at_sql} and srr.store_id=#{store_id} and
                          srr.types=#{SvcReturnRecord::TYPES[:OUT]}"
    order_svc_returns = SvcReturnRecord.find_by_sql(relation_order_sql)

    relation_material_order_sql = "select srr.*,mo.code code,mo.id mo_id from svc_return_records srr
                          left join material_orders mo on mo.id = srr.target_id where #{started_at_sql}
                          and #{ended_at_sql} and srr.store_id=#{store_id} and
                          srr.types=#{SvcReturnRecord::TYPES[:IN]}"
    material_order_svc_returns = SvcReturnRecord.find_by_sql(relation_material_order_sql)

    (order_svc_returns + material_order_svc_returns).sort{|a,b| a[:id] <=> b[:id]}
  end
end