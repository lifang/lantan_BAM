#encoding: utf-8
class MonthScoresController < ApplicationController
  layout "complaint", :except => ['update', 'update_sys_score']
  
  def update
    @store = Store.find_by_id(params[:store_id])
    month_score = MonthScore.find_by_id(params[:id])
    month_score.update_attributes(params[:month_score]) if month_score
    @month_scores = month_score.staff.month_scores.
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    respond_to do |format|
      format.js
    end
  end

  def update_sys_score
    month_score = MonthScore.find_by_id(params[:month_score_id])
    month_score.update_attribute(:sys_score, params[:sys_score]) if month_score
    render :text => "success"
  end

  #营业额汇总表
  def makets_totals
    @month_goal =MonthScore.sort_order(params[:store_id])
    @months =@month_goal.inject(Hash.new){|hash,order|
      hash[order.day].nil? ? hash[order.day]={order.pay_type=>order.price} : hash[order.day].merge!(order.pay_type=>order.price);hash }
    @total_num =@month_goal.inject(0){|num,order| num+order.price}
  end
  
  #营业额汇总查询
  def search_month
    session[:created],session[:ended]=nil,nil
    session[:created],session[:ended]=params[:created],params[:ended]
    redirect_to "/stores/#{params[:store_id]}/month_scores/makets_list"
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
    redirect_to "/stores/#{params[:store_id]}/month_scores/makets_views"
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
  def makets_goal

  end
end
