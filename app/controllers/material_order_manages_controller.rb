#encoding:utf-8
class MaterialOrderManagesController < ApplicationController
  before_filter :sign?
  layout "complaint"

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

end
