#encoding: utf-8
class WelcomesController < ApplicationController
  before_filter :sign?
  before_filter :customer_tips

  def index
    @material_notices = Notice.find_all_by_store_id_and_types_and_status(params[:store_id].to_i,
      Notice::TYPES[:URGE_PAYMENT], Notice::STATUS[:NORMAL])
    @material_orders_send = MaterialOrder.count(:id, :conditions => ["m_status = ?", MaterialOrder::M_STATUS[:send]])
    @material_orders_received = MaterialOrder.count(:id, :conditions => ["m_status = ?", MaterialOrder::M_STATUS[:received]])
    render :index, :layout => false
  end
end
