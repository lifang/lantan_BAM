#encoding: utf-8
class ComplaintsController < ApplicationController
  before_filter :sign?
  layout "complaint"
  require 'will_paginate/array'

  #投诉分类统计
  def index
    @complaint = Complaint.get_chart(params[:store_id])
    @complaint = Complaint.gchart(params[:store_id])  if @complaints.blank?
    @complaint = ChartImage.where("store_id=#{params[:store_id]} and types=#{ChartImage::TYPES[:COMPLAINT]}").order("created_at desc")[0]  if @complaint.nil?
    session[:created_at]=@complaint.nil? ? nil : @complaint.current_day.strftime("%Y-%m")
    session[:start_sex],session[:end_sex],session[:sex]=Time.now.beginning_of_month.strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d"),Complaint::SEX[:NONE] 
    @total_com = Complaint.show_types(params[:store_id],session[:start_sex],session[:end_sex],session[:sex])
    @size = ((@total_com.values.max.nil? ? 1 :@total_com.values.max)/10+1)*10#生成图表的y的坐标
  end

  #投诉分类查询
  def search
    session[:created_at]=nil
    session[:created_at]=params[:created_at]
    redirect_to "/stores/#{params[:store_id]}/complaints/search_list"
  end

  #投诉分类查询列表
  def search_list
    @complaint =Complaint.search_lis(params[:store_id],session[:created_at])
    @total_com = Complaint.show_types(params[:store_id],session[:start_sex],session[:end_sex],session[:sex])
    @size = ((@total_com.values.max.nil? ? 1 :@total_com.values.max)/10+1)*10#生成图表的y的坐标
    render 'index'
  end

  #投诉分类按时间和性别查询统计
  def search_time
    session[:start_sex],session[:end_sex],session[:sex]=nil,nil,nil
    session[:start_sex],session[:end_sex],session[:sex]=params[:start_sex],params[:end_sex],params[:sex]
    redirect_to "/stores/#{params[:store_id]}/complaints/date_list"
  end
  
  #投诉分类按时间和性别查询统计列表
  def date_list
    @complaint =Complaint.search_lis(params[:store_id],session[:created_at])
    @total_com = Complaint.show_types(params[:store_id],session[:start_sex],session[:end_sex],session[:sex])
    @size = ((@total_com.values.max.nil? ? 1 :@total_com.values.max)/10+1)*10#生成图表的y的坐标
    render 'index'
  end

  #投诉详细页
  def show_detail
    total = Complaint.search_detail(params[:store_id])
    @complaint = total.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    non_time = Complaint.search_detail(params[:store_id],0)
    un_done = Complaint.search_detail(params[:store_id],1)
    @staff_name ={}
    @complaint.each do |comp|
      @staff_name[comp.id]=Staff.where("id in (#{comp.staff_id_1},#{comp.staff_id_2})").map(&:name).join("、 ") if comp.staff_id_1 and comp.staff_id_2
    end
    @non =(non_time.size*100.0/total.size).round(1)
    @undo =((total.size-un_done.size)*100.0/total.size).round(1)
  end

  #满意度统计页
  def satisfy_degree
    @degree = Complaint.count_pleasant(params[:store_id])
    @degree = Complaint.degree_chart(params[:store_id])  if @degree.blank?
    @degree = ChartImage.where("store_id=#{params[:store_id]} and types=#{ChartImage::TYPES[:SATIFY]}").order("created_at desc")[0]  if @degree.nil?
    session[:degree]= @degree.nil? ? nil : @degree.current_day.strftime("%Y-%m")
    session[:start_degree],session[:end_degree],session[:sex_degree]=Time.now.beginning_of_month.strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d"),Complaint::SEX[:NONE]
    @total_com = Complaint.degree_day(params[:store_id],session[:start_degree],session[:end_degree],session[:sex_degree])
  end

  #满意度图标
  def degree_time
    session[:start_degree],session[:end_degree],session[:sex_degree]=nil,nil,nil
    session[:start_degree],session[:end_degree],session[:sex_degree]=params[:start_degree],params[:end_degree],params[:sex]
    redirect_to "/stores/#{params[:store_id]}/complaints/time_list"
  end
  
  #按照查询的日期生成满意度
  def time_list
    @degree =Complaint.degree_lis(params[:store_id],session[:degree])
    @total_com = Complaint.degree_day(params[:store_id],session[:start_degree],session[:end_degree],session[:sex_degree])
    render 'satisfy_degree'
  end

  #满意度查询
  def search_degree
    session[:degree]=nil
    session[:degree]=params[:degree]
    redirect_to "/stores/#{params[:store_id]}/complaints/degree_list"
  end

  #满意度查询列表
  def degree_list
    @degree =Complaint.degree_lis(params[:store_id],session[:degree])
    @total_com = Complaint.degree_day(params[:store_id],session[:start_degree],session[:end_degree],session[:sex_degree])
    p @total_com
    render 'satisfy_degree'
  end

  #投诉详细查询
  def detail_s
    session[:detail]=nil
    session[:detail] =params[:detail]
    redirect_to "/stores/#{params[:store_id]}/complaints/detail_list"
  end
  
  #投诉详细查询列表
  def detail_list
    @complaint =Complaint.detail_one(params[:store_id],params[:page],session[:detail])
    total =Complaint.search_one(params[:store_id],session[:detail])
    non_time =Complaint.search_one(params[:store_id],session[:detail],0)
    un_done =Complaint.search_one(params[:store_id],session[:detail],1)
    @staff_name ={}
    @complaint.each do |comp|
      @staff_name[comp.id]=Staff.where("id in (#{comp.staff_id_1},#{comp.staff_id_2})").map(&:name).join("、 ") if comp.staff_id_1 and comp.staff_id_2
    end
    @non =(non_time.num*100.0/total.num).round(1)
    @undo =((total.num-un_done.num)*100.0/total.num).round(1)
    render 'show_detail'
  end

  #客户-投诉-点击详细
  def complaint_detail
    @store = Store.find_by_id(params[:store_id])
    @complaint = @store.complaints.find_by_id(params[:id])
    @staff_names = Staff.where(:id => [@complaint.staff_id_1, @complaint.staff_id_2].compact).map(&:name).join(", ")
    @violation_rewards = ViolationReward.find_by_sql("select vr.*, s.name name from violation_rewards vr inner join staffs s on vr.staff_id = s.id where target_id = #{ @complaint.id}")
  end

  #客户消费统计
  def consumer_list
    session[:list_start],session[:list_end],session[:list_prod],session[:list_sex],session[:list_year]=nil,nil,nil,nil,nil
    session[:list_fee],session[:list_model],session[:list_name]=nil,nil,nil
    @consumers = Complaint.consumer_types(params[:store_id],1)
    unless @consumers.blank?
      products =Product.find_by_sql("select p.name,o.price,o.pro_num,o.order_id,o.total_price from products p inner join order_prod_relations o on o.product_id=p.id where
      o.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
      @products = products.inject(Hash.new){|hash,prod|hash[prod.order_id].nil? ? hash[prod.order_id]=[prod]:hash[prod.order_id]<<prod;hash}
      p @products
      pay_sql = "select * from order_pay_types  where order_id in (#{@consumers.map(&:id).uniq.join(",")}) and
       pay_type in (#{OrderPayType::PAY_TYPES[:SV_CARD]},#{OrderPayType::PAY_TYPES[:PACJAGE_CARD]},#{OrderPayType::PAY_TYPES[:SALE]})"
      prices =OrderPayType.find_by_sql(pay_sql).inject(Hash.new){|hash,order_pay|hash[order_pay.order_id].nil? ? hash[order_pay.order_id]=order_pay.price : hash[order_pay.order_id]+=order_pay.price;hash}
      @sums ={}
      products.inject(Hash.new){|hash,prod|hash[prod.order_id].nil? ? hash[prod.order_id]= prod.total_price : hash[prod.order_id]+= prod.total_price;hash}.each {|key,value|@sums[key]=(value.nil? ? 0 : value)-(prices[key].nil? ? 0 :prices[key])  }
    end
  end

  #消费客户查询
  def consumer_search
    session[:list_start],session[:list_end],session[:list_prod],session[:list_sex],session[:list_year]=nil,nil,nil,nil,nil
    session[:list_fee],session[:list_model],session[:list_name]=nil,nil,nil
    session[:list_start],session[:list_end],session[:list_prod],session[:list_sex]=params[:list_start],params[:list_end],params[:list_prod],params[:list_sex]
    session[:list_year],session[:list_fee],session[:list_model],session[:list_name]=params[:list_year],params[:list_fee],params[:list_model],params[:list_name]
    redirect_to "/stores/#{params[:store_id]}/complaints/con_list"
  end

  #客户消费统计查询
  def con_list
    @consumers = Complaint.consumer_types(params[:store_id],0,session[:list_start],session[:list_end],session[:list_sex],session[:list_model],session[:list_year],session[:list_name],session[:list_fee])
    unless @consumers.blank?
      sql ="select p.name,o.price,o.pro_num,o.order_id,o.total_price from products p inner join order_prod_relations o on o.product_id=p.id where
      o.order_id in (#{@consumers.map(&:id).uniq.join(",")})"
      sql += " and p.types =#{session[:list_prod]}" unless session[:list_prod].nil? || session[:list_prod] =="" || session[:list_prod].length==0
      products =Product.find_by_sql(sql)
      @products = products.inject(Hash.new){|hash,prod|hash[prod.order_id].nil? ? hash[prod.order_id]=[prod]:hash[prod.order_id]<<prod;hash}
      pay_sql = "select * from order_pay_types o inner join products p on p.id=o.product_id where o.order_id in (#{@consumers.map(&:id).uniq.join(",")}) and
       o.pay_type in (#{OrderPayType::PAY_TYPES[:SV_CARD]},#{OrderPayType::PAY_TYPES[:PACJAGE_CARD]},#{OrderPayType::PAY_TYPES[:SALE]})"
      sql += " and p.types =#{session[:list_prod]}" unless session[:list_prod].nil? || session[:list_prod] =="" || session[:list_prod].length==0
      prices =OrderPayType.find_by_sql(pay_sql).inject(Hash.new){|hash,order_pay|hash[order_pay.order_id].nil? ? hash[order_pay.order_id]=order_pay.price : hash[order_pay.order_id]+=order_pay.price;hash}
      @sums ={}
      products.inject(Hash.new){|hash,prod|hash[prod.order_id].nil? ? hash[prod.order_id]= prod.total_price : hash[prod.order_id]+= prod.total_price;hash}.each {|key,value|@sums[key]=(value.nil? ? 0 : value)-(prices[key].nil? ? 0 :prices[key])  }
    end
    render "consumer_list"
  end
end
