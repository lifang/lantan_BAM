#encoding:utf-8
require 'date'
require 'will_paginate/array'
class MaterialOrderManagesController < ApplicationController
  before_filter :sign?
  layout "complaint"
  respond_to :json, :xml, :html
  before_filter :make_search_sql, :only => [:mat_in_or_out_query,:search_mat_in_or_out,:page_ins,:page_outs,:search_unsalable_materials,:unsalable_materials,:page_unsalable_materials]
  before_filter :get_store, :only => [:mat_in_or_out_query,:search_mat_in_or_out,:page_ins,:page_outs,:search_unsalable_materials,:unsalable_materials,:page_unsalable_materials]
  def index
    @store = Store.find_by_id(params[:store_id])
    @statistics_month = (params[:statistics_month] ||= Time.now.months_ago(1).strftime("%Y-%m"))
    arrival_at_sql = "arrival_at>='#{@statistics_month}-01' and date_format(arrival_at,'%Y-%m-%d')<='#{@statistics_month}-31'"
    @material_orders = MaterialOrder.where("store_id = #{params[:store_id]}").where(arrival_at_sql)
    @total_price = @material_orders.sum(:price)
  end

  def show
    @store = Store.find_by_id(params[:store_id])
    material_order = MaterialOrder.find_by_id(params[:id])
    @mat_order_items = material_order.nil? ? [] : material_order.mat_order_items
    respond_to do |format|
      format.js
    end
  end

  def mat_in_or_out_query
    @mat_in_orders = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id].to_i
    @mat_out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id].to_i
  end

  #入/出库查询
  def search_mat_in_or_out
    @mat_in_or_out = mat_in_or_out = params[:mat_in_or_out]
    start_date = params[:start_date]
    end_date = params[:end_date]
    @status = 0
    if(start_date.empty? || end_date.empty?)
           @status = 0
    else
        if Date.parse(start_date)>Date.parse(end_date)
           @status = 1
        end
    end

    if @status == 0
      if mat_in_or_out == "ruku"
        @mat_in_orders = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id].to_i,@sql
      elsif mat_in_or_out == "chuku"
        @mat_out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id].to_i,@sql
      end
    else
       @mat_in_orders = []
       @mat_out_records = []
    end
  end

  #滞销物料显示
  def unsalable_materials
    @end_date = Time.now.to_s[0..9]
    @start_date  =  (Time.now - 30.day).to_s[0..9]
    #@all_unsalable_materials = Material.unsalable_list params[:store_id].to_i
    @all_unsalable_materials  = Material.find_by_sql("select * from materials where id not in (SELECT material_id as id FROM mat_out_orders  where created_at >= '#{@start_date} 00:00:00' and created_at <= '#{@end_date} 23:59:59'
      and  types = 3 and store_id = #{@current_store.id} group by material_id having count(material_id) >= 1) and store_id = #{@current_store.id} and status != #{Material::STATUS[:DELETE]};")
    @unsalable_materials = @all_unsalable_materials.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    #@unsalable_materials = @all_unsalable_materials.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
  end

  def search_unsalable_materials
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @mat_type = params[:mat_types]
    @sale_num = params[:sale_num]
      @u_sql = []
      @u_sql << @start_date << @end_date << @sale_num << @mat_type

      @status = false
      if (@start_date.blank? || @end_date.blank?)
        @all_unsalable_materials = Material.unsalable_list params[:store_id],@u_sql
        @unsalable_materials = @all_unsalable_materials.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
        @status = true
      else
        if Date.parse(@start_date)>Date.parse(@end_date)
          @all_unsalable_materials = []
          @unsalable_materials = []
          @status = false
        else
          @all_unsalable_materials = Material.unsalable_list params[:store_id],@u_sql
          @unsalable_materials = @all_unsalable_materials.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
          @status = true
        end
      end
  end

  def page_unsalable_materials
    @u_sql = []
    @u_sql << @start_date << @end_date << @sale_num << @mat_type
    @all_unsalable_materials = Material.unsalable_list params[:store_id],@u_sql
    @unsalable_materials = @all_unsalable_materials.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    respond_with(@unsalable_materials) do |f|
      f.html
      f.js
    end
  end

  #入库列表分页
  def page_ins
    @mat_in_orders = MatInOrder.in_list params[:page],Constant::PER_PAGE, params[:store_id].to_i,@sql

    respond_with(@mat_in_orders) do |f|
      f.html
      f.js
    end
  end

  #出库列表分页
  def page_outs
    @mat_out_records = MatOutOrder.out_list params[:page],Constant::PER_PAGE, params[:store_id].to_i,@sql

    respond_with(@mat_out_records) do |f|
      f.html
      f.js
    end
  end

  protected

  def make_search_sql
    start_date = params[:start_date].blank? ? "1 = 1" : ["o.created_at >= '#{params[:start_date]} 00:00:00' "]
    end_date = params[:end_date].blank? ? "1 = 1" : ["o.created_at <='#{params[:end_date]} 23:59:59' "]
    mat_types = params[:mat_types].blank? || params[:mat_types] == "-1" ? "1 = 1" : ["materials.types = ?", params[:mat_types].to_i]
    @sql = []
    @sql << start_date << end_date << mat_types
    @start_date = params[:start_date].blank? ? nil : params[:start_date]
    @end_date = params[:end_date].blank? ? nil : params[:end_date]
    @mat_type = params[:mat_types].blank? ? nil : params[:mat_types]
  end

  def get_store
    @current_store = Store.find_by_id(params[:store_id].to_i)
  end

end
