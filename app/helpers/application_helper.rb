#encoding: utf-8
module ApplicationHelper
  include Constant
  include UserRoleHelper

  #客户管理提示信息
  def customer_tips
    @complaints = Complaint.find_all_by_store_id_and_status(params[:store_id].to_i, Complaint::STATUS[:UNTREATED])
    @notices = Notice.find_all_by_store_id_and_types_and_status(params[:store_id].to_i,
      Notice::TYPES[:BIRTHDAY], Notice::STATUS[:NOMAL])
  end
end
