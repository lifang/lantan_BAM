#encoding: utf-8
class OrdersController < ApplicationController
  def order_info
    @order = Order.one_order_info(params[:id].to_i)
    @order_prods = OrderProdRelation.order_products(@order)
    @sale = Sale.find(@order[0].sale_id) if @order[0] and @order[0].sale_id
    respond_to do |format|
      format.js
    end
  end

  def order_staff
    ids = params[:id].split("_")
    @complaint_id = ids[0]
    @order = Order.one_order_info(ids[1].to_i)[0]
    respond_to do |format|
      format.js
    end
  end
end
