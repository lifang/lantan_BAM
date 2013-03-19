#encoding: utf-8
class StaffManagesController < ApplicationController
  layout "complaint"

  before_filter :get_store

  def index
    @staffs = Staff.where("store_id = #{params[:store_id]}")
  end


  def show
    @staff = Staff.find_by_id(params[:id])

    year = Time.now.strftime("%Y")

    month = Time.now.months_ago(1).strftime("%m")
    base_sql = "current_day >= '#{year}-#{month}-01 00:00:00' and current_day <= '#{year}-#{month}-31 23:59:59'"
    chart_image = ChartImage.where("types = #{ChartImage::TYPES[:STAFF_LEVEL]} and staff_id = #{@staff.id}").
      where(base_sql).
      where("store_id = #{@store.id}").
      order("created_at desc").first
    @chart_url = chart_image.image_url unless chart_image.nil?

    respond_to do |format|
      format.js
    end
  end

  def get_year_staff_hart
    @staff = Staff.find_by_id(params[:id])
    year = params[:year]

    base_sql = get_base_sql(year)

    chart_image = ChartImage.where("types = #{ChartImage::TYPES[:STAFF_LEVEL]} and staff_id = #{@staff.id}").
      where(base_sql).
      where("store_id = #{params[:store_id]}").
      order("created_at desc").first
    chart_url = chart_image.image_url unless chart_image.nil?

    render :text => chart_url
  end

  def average_score_hart
    @year = params[:year] ||= Time.now.strftime("%Y")

    base_sql = get_base_sql(@year)

    technician_chart_image = ChartImage.
      where("types = #{ChartImage::TYPES[:MECHINE_LEVEL]}").
      where(base_sql).
      order('created_at desc').first
    @avg_technician = technician_chart_image.image_url unless technician_chart_image.nil?

    front_chart_image = ChartImage.
      where("types = #{ChartImage::TYPES[:FRONT_LEVEL]}").
      where(base_sql).
      order('created_at desc').first
    @avg_front = front_chart_image.image_url unless front_chart_image.nil?

  end

  def get_base_sql(year)
    if year == Time.now.strftime("%Y")
      month = Time.now.months_ago(1).strftime("%m")
      base_sql = "current_day >= '#{year}-#{month}-01 00:00:00' and current_day <= '#{year}-#{month}-31 23:59:59'"
    else
      base_sql = "current_day >= '#{year}-12-01 00:00:00' and current_day <= '#{year}-12-31 23:59:59'"
    end
    return base_sql
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end
