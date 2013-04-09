#encoding: utf-8
class ComplaintsController < ApplicationController
  before_filter :sign?
  layout "complaint"
  require 'will_paginate/array'

  #投诉分类统计
  def index
    session[:created_at]=nil
    @complaint = Complaint.get_chart(params[:store_id])
    @complaint = Complaint.gchart(params[:store_id])  if @complaints.blank?
    @complaint = ChartImage.where("store_id=#{params[:store_id]} and types=#{ChartImage::TYPES[:COMPLAINT]}").order("created_at desc")[0]  if @complaint.nil?
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
end
