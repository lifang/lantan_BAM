#encoding: utf-8
class MarketManagesController < ApplicationController
  layout "complaint"
  require 'will_paginate/array'

  #营业额汇总表
  def makets_totals
    session[:created],session[:ended]=nil,nil
    @month_goal =MonthScore.sort_order(params[:store_id])
    @months =@month_goal.inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : hash[order.day].merge!(order.pay_type=>order.price);hash }
    @total_num =@month_goal.inject(0){|num,order| num+order.price}
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
    @sale_orders =  orders.paginate(:page=>params[:page],:per_page=>10)
    @sale_names =orders.map(&:name)
  end

  def search_sale_order
    session[:o_created],session[:o_ended],session[:order_name]=nil,nil,nil
    session[:o_created],session[:o_ended],session[:order_name]=params[:o_created],params[:o_ended],params[:order_name]
    redirect_to "/stores/#{params[:store_id]}/market_manages/sale_order_list"
  end

  def sale_order_list
    orders = Sale.count_sale_orders_search(params[:store_id],session[:o_created],session[:o_ended],session[:order_name])
    @sale_orders =  orders.paginate(:page=>params[:page],:per_page=>10)
    @sale_names =Sale.count_sale_orders_search(params[:store_id]).map(&:name)
    render 'sale_orders'
  end
end