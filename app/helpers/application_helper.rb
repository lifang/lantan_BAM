#encoding: utf-8
module ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  include Constant
  include UserRoleHelper
  include Oauth2Helper

  def sign?
    deny_access unless signed_in?
  end

  def deny_access
    redirect_to "/logins"
  end

  def signed_in?
    return (cookies[:user_id] != nil and ((params[:store_id].nil? and @store.nil?) or current_user.store_id == params[:store_id].to_i or (@store and current_user.store_id == @store.id)))
  end

  def current_user
    return Staff.find_by_id(cookies[:user_id].to_i)
  end

  #客户管理提示信息
  def customer_tips
    @complaints = Complaint.find_by_sql(["select c.id, c.reason, c.suggestion, o.code, cu.name, ca.num, cu.id cu_id, o.id o_id
      from complaints c inner join orders o on o.id = c.order_id
      inner join customers cu on cu.id = c.customer_id inner join car_nums ca on ca.id = o.car_num_id 
      where c.store_id = ? and c.status = ? ", params[:store_id].to_i, Complaint::STATUS[:UNTREATED]])
    
    @notices = Customer.find_by_sql("select DISTINCT(c.id), c.name from customers c
      left join customer_store_relations csr on csr.customer_id = c.id
      where c.status = #{Customer::STATUS[:NOMAL]} 
      and csr.store_id in(#{StoreChainsRelation.return_chain_stores(params[:store_id].to_i).join(",")}) 
      and c.birthday is not null and
      ((month(now())*30 + day(now()))-(month(c.birthday)*30 + day(c.birthday))) <= 0
      and ((month(now())*30 + day(now()))-(month(c.birthday)*30 + day(c.birthday))) > -7")
  end

  def staff_names
    names = []
    staffs = Staff.find_by_sql("select id,name from staffs where status = #{Staff::STATUS[:normal]}")
    idx = 0
    staffs.each do |staff|
      names[idx] = []
      names[idx] << "#{staff.name}" << staff.id
      idx+=1
    end
    names
  end

  def from_s store_id
    a = Item.new
    a.id = 0
    a.name = "总部"
    suppliers = [a] + Supplier.all(:select => "s.id,s.name", :from => "suppliers s",
      :conditions => "s.store_id=#{store_id} and s.status=0")
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
      elsif status == 4
        str = "已退货"
      end
    end
    str
  end

  def role_model relations,func_num,model_name
    check = false
    arr = []
    (relations || []).each do |relation|
      if relation && relation.model_name == model_name
        arr << relation
      end
    end
    (arr || []).each do |relation|
      if relation && relation.num == func_num
        check = true
        break
      end
    end
    check
  end

  def get_last_twelve_months
    months = []
    12.times do |i|
      months << DateTime.now.months_ago(i+1).strftime("%Y-%m")
    end
    months
  end

  def create_get_http(url,route)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.port==443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request= Net::HTTP::Get.new(route)
    back_res =http.request(request)
    return JSON back_res.body
  end

  def satisfy
    orders = Order.find(:all, :select => "is_pleased", 
      :conditions => [" store_id = ? and status in (#{Order::STATUS[:BEEN_PAYMENT]}, #{Order::STATUS[:FINISHED]}) and created_at > ? and created_at < ?",
        params[:store_id].to_i, Time.mktime(Time.now.year, Time.now.mon-1, 1), Time.mktime(Time.now.year, Time.now.mon, 1)])
    un_pleased_size = 0
    orders.collect { |o| un_pleased_size += 1 if o.is_pleased == Order::IS_PLEASED[:BAD] }
    pleased = orders.size == 0 ? 0 : (orders.size - un_pleased_size)*100/orders.size
    unpleased = orders.size == 0 ? 0 : 100 - pleased
    return [pleased, unpleased]
  end

  def material_order_tips
    @material_pay_notices = Notice.find_all_by_store_id_and_types_and_status(params[:store_id].to_i,
      Notice::TYPES[:URGE_PAYMENT], Notice::STATUS[:NORMAL])
    @material_orders_received = MaterialOrder.where("m_status = ? and supplier_id = ? and store_id = ?", MaterialOrder::M_STATUS[:received], 0, params[:store_id])
    @material_orders_send = MaterialOrder.where("m_status = ? and supplier_id = ? and store_id = ?", MaterialOrder::M_STATUS[:send], 0, params[:store_id])
    store = Store.find_by_id(params[:store_id].to_i)
    @low_materials = Material.where(["status = ? and store_id = ? and storage <= material_low and is_ignore = ?", Material::STATUS[:NORMAL],
        store.id, Material::IS_IGNORE[:NO]]) if store
  end

  def random_file_name(file_name)
    name = File.basename(file_name)
    return (Digest::SHA1.hexdigest Time.now.to_s + name)[0..20]
  end

  def proof_code(len)
    chars = ('A'..'Z').to_a + ('a'..'z').to_a + (0..9).to_a
    code_array = []
    1.upto(len) {code_array << chars[rand(chars.length)]}
    return code_array.join("")
  end


  #物料
  def get_mo(material,material_orders)
    mos = {}
    material_orders.each do |material_order|
      mio_num = MatInOrder.where(:material_id => material.id, :material_order_id => material_order.id).sum(:material_num)
      moi_num = MatOrderItem.find_by_material_id_and_material_order_id(material.id, material_order.id).try(:material_num)
      if mio_num < moi_num
        mos[material_order] = moi_num - mio_num
      end
    end
    mos
  end



  #根据订单分组
  def order_by_status(orders)
    orders = orders.group_by{|order| order.status}
    #把免单的order放在已付款下面
    if orders[Order::STATUS[:FINISHED]].present?
      orders[Order::STATUS[:BEEN_PAYMENT]] ||= []
      orders[Order::STATUS[:BEEN_PAYMENT]] = (orders[Order::STATUS[:BEEN_PAYMENT]] << orders[Order::STATUS[:FINISHED]]).flatten
      orders.delete(Order::STATUS[:FINISHED])
    end
    orders
  end

  #
  def combin_orders(orders)
    orders.map{|order|
      work_order = WorkOrder.find_by_order_id(order.id)
      service_name = Order.find_by_sql("select p.name p_name from orders o inner join order_prod_relations opr on opr.order_id=o.id inner join
            products p on p.id=opr.product_id where p.is_service=#{Product::PROD_TYPES[:SERVICE]} and o.id = #{order.id}").map(&:p_name).compact.uniq
      order[:wo_started_at] = (work_order && work_order.started_at && work_order.started_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:wo_ended_at] = (work_order && work_order.ended_at && work_order.ended_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:car_num] = order.car_num.try(:num)
      order[:service_name] = service_name.join(",")
      order[:cost_time] = work_order.try(:cost_time)
      order[:station_id] = work_order.try(:station_id)
    }
    orders
  end


  def check_str(str)
    no_ch = str.gsub(/[\u4e00-\u9fa5]/,"").bytesize
#    no_ch_en = str.gsub(/[\u4e00-\u9fa5]/,"").gsub(/[a-zA-z]/,"").bytesize
    return (str.bytesize-no_ch)+no_ch*1.5
  end

end
