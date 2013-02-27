#encoding: utf-8
module ApplicationHelper
  include Constant
  include UserRoleHelper

  #客户管理提示信息
  def customer_tips
    @complaints = Complaint.find_by_sql(["select c.reason, c.suggstion, o.code, cu.name, ca.num, cu.id cu_id
      from complaints c inner join orders o on o.id = c.order_id
      inner join customers cu on cu.id = c.customer_id inner join car_nums ca on ca.id = o.car_num_id 
      where c.store_id = ? and c.status = ? ", params[:store_id].to_i, Complaint::STATUS[:UNTREATED]])
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

  def cover_div controller_name
    return request.url.include?(controller_name) ? "hover" : ""
    #puts self.action_name,self.controller_path,self.controller,self.controller_name,request.url
  end

  def material_status status, type
   str = ""
    if type == 0
     if status == 0
       str = "未付款"
     elsif status == 1
       str = "已付款"
     elsif status == 4
       str = "已取消"
     end
    elsif type == 1
      if status == 0
        str = "未发货"
      elsif status == 1
        str = "已发货"
      elsif status == 2
        str = "已收货"
      elsif status == 3
        str = "已入库"
      end
    end
    str
  end
end
