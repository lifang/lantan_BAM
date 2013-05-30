#encoding: utf-8
class RevisitsController < ApplicationController
  before_filter :sign?
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
          :store_id => params[:store_id].to_i, :types => Complaint::TYPES[:OTHERS]) if params[:is_complaint]
        revisit = Revisit.create(:customer_id => params[:rev_customer_id].to_i, :types => params[:rev_types].to_i,
          :title => params[:rev_title], :answer => params[:rev_content], :content => params[:rev_answer],
          :complaint_id => (complaint.nil? ? nil : complaint.id))
        RevisitOrderRelation.create(:order_id => params[:rev_order_id].to_i, :revisit_id => revisit.id)
        order = Order.find(params[:rev_order_id].to_i)
        order.update_attributes(:is_visited => true) unless order.is_visited
      end
      flash[:notice] = "添加回访成功。"
    end
    redirect_to request.referer
  end

  def process_complaint
    flash[:notice] = "处理失败，请您重新尝试。"
    if params[:prod_type]
      staff_ids = params[:c_staff_id].split(",") unless params[:c_staff_id].nil?
      staff_id_1, staff_id_2 = staff_ids[0], staff_ids[1] if staff_ids
      is_violation = params[:prod_type].to_i < Complaint::TYPES[:INVALID] ? true : false
      status = params[:cfs].to_i == Complaint::STATUS[:PROCESSED] ? true : false
      complaint = Complaint.find(params[:pro_compl_id].to_i)
      complaint.update_attributes(:types => params[:prod_type].to_i, :remark => params[:pro_remark],
        :status => status, :is_violation => is_violation, :process_at => status ? Time.now : nil,
        :staff_id_1 => staff_id_1, :staff_id_2 => staff_id_2, :c_feedback_suggestion => status)
      vr1 = ViolationReward.find_by_target_id_and_staff_id(complaint.id, staff_id_1)
      vr2 = ViolationReward.find_by_target_id_and_staff_id(complaint.id, staff_id_2)
      
      violation_hash = {:status => ViolationReward::STATUS[:NOMAL],
        :situation => "订单#{params[:pc_code]}产生投诉，#{Complaint::TYPES_NAMES[params[:prod_type].to_i]}",
        :types => ViolationReward::TYPES[:VIOLATION], :target_id => complaint.id}
      ViolationReward.create(violation_hash.merge({:staff_id => staff_id_1})) if staff_id_1 and !vr1
      ViolationReward.create(violation_hash.merge({:staff_id => staff_id_2})) if staff_id_2 and !vr2
      flash[:notice] = "处理投诉成功。"
    end
    if params["is_trains_#{params[:pro_compl_id]}"] == "0"
      redirect_to request.referer
    else
      redirect_to "/stores/#{params[:store_id]}/staffs"
    end
  end

  
end
