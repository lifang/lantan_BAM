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

  def material_types
    types = []
    items = Material::TYPES_NAMES.to_a.each_with_index{|item,idx|
      types[idx] = [item[1],item[0]]
    }
    types
  end

  def from_s store_id
    a = Item.new
    a.id = 0
    a.name = "总部"
    suppliers = [a] + Supplier.all(:select => "s.id,s.name", :from => "suppliers s",
                                   :conditions => "s.store_id=#{store_id}")
    suppliers
  end

end
