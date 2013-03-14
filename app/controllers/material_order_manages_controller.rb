#encoding:utf-8
class MaterialOrderManagesController < ApplicationController

  layout "complaint"

  def index
    @store = Store.find_by_id(params[:store_id])

    @statistics_month = (params[:statistics_month] ||= Time.now.strftime("%Y-%m"))

    arrival_at_sql = "arrival_at >= '#{@statistics_month}-01' and arrival_at <= '#{@statistics_month}-31'"

    @material_orders = MaterialOrder.
                    where("store_id = #{params[:store_id]}").
                    where(arrival_at_sql)

    @total_price = @material_orders.sum(:price)
  end

end
