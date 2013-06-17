#encoding: utf-8
class OrdersController < ApplicationController
  before_filter :sign?
  
  def order_info
    @order = Order.one_order_info(params[:id].to_i)
    @order_prods = OrderProdRelation.order_products(@order)
    @sale = Sale.find_by_id(@order[0].sale_id) if @order[0] and @order[0].sale_id
    @order_pay_types = OrderPayType.find_by_sql(["select sum(opt.price) total_price,
      ifnull(sum(opt.product_num), 0) total_num, opt.pay_type from order_pay_types opt
      where opt.order_id = ? group by opt.pay_type",
        @order[0].id]).group_by { |item| item.pay_type } if @order[0]
    respond_to do |format|
      format.js
    end
  end

  def order_staff
    ids = params[:id].split("_")
    @complaint_id = ids[0]
    @comp_page = params[:comp_page].empty? ? 1 : params[:comp_page]
    @order = Order.one_order_info(ids[1].to_i)[0]
    respond_to do |format|
      format.js
    end
  end
end
