#encoding: utf-8
class RevisitsController < ApplicationController
  layout "customer"
  
  def index
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:is_vip] = nil
    session[:is_visited] = nil
    session[:is_time] = "1"
    session[:time] = nil
    session[:is_price] = "1"
    session[:price] = nil
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_order_customers(@store.id, (Time.now - 15.days).to_date.to_s, Time.now.to_date.to_s, nil, "1",
      "3", "1", "500", nil, nil, params[:page])
  end

  def search
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:is_vip] = params[:is_vip]
    session[:is_visited] = params[:is_visited]
    session[:is_time] = params[:is_time]
    session[:time] = params[:time]
    session[:is_price] = params[:is_price]
    session[:price] = params[:price]
    redirect_to "/stores/#{params[:store_id]}/revisits/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_order_customers(@store.id, session[:started_at], session[:ended_at], session[:is_visited],
      session[:is_time], session[:time], session[:is_price], session[:price], session[:is_vip], nil, params[:page])
    render "index"
  end

  def create
    flash[:notice] = "创建回访失败，请您重新尝试。"
    if params[:rev_title]
      Revisit.transaction do
        complaint = Complaint.create(:order_id => params[:rev_order_id].to_i, :reason => params[:rev_answer],
          :status => Complaint::STATUS[:UNTREATED], :customer_id => params[:rev_customer_id].to_i,
          :store_id => params[:store_id].to_i) if params[:is_complaint]
        revisit = Revisit.create(:customer_id => params[:rev_customer_id].to_i, :types => params[:rev_types].to_i,
          :title => params[:rev_title], :answer => params[:rev_content], :content => params[:rev_answer],
          :complaint_id => (complaint.nil? ? nil : complaint.id))
        RevisitOrderRelation.create(:order_id => params[:rev_order_id].to_i, :revisit_id => revisit.id)
      end
      flash[:notice] = "添加回访成功。"
    end
    redirect_to request.referer
  end

  def process
    flash[:notice] = "处理失败，请您重新尝试。"
    if params[:prod_type]
      complaint = Complaint.find(params[:pro_compl_id].to_i)
      complaint.update_attributes(:types => params[:prod_type].to_i, :remark => params[:pro_remark],
        :status => Complaint::STATUS[:PROCESSED])
      
    end
  end
  
end
