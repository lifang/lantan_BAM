#encoding: utf-8
module ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  include Constant
  include UserRoleHelper

  def sign?
    puts "------------------------------------"
    puts signed_in?
    deny_access unless signed_in?
  end

  def deny_access
    redirect_to "/logins"
  end

  def signed_in?
    return cookies[:user_id] != nil
  end

  #客户管理提示信息
  def customer_tips
    @complaints = Complaint.find_by_sql(["select c.reason, c.suggestion, o.code, cu.name, ca.num, cu.id cu_id, o.id o_id
      from complaints c inner join orders o on o.id = c.order_id
      inner join customers cu on cu.id = c.customer_id inner join car_nums ca on ca.id = o.car_num_id 
      where c.store_id = ? and c.status = ? ", params[:store_id].to_i, Complaint::STATUS[:UNTREATED]])
    @notices = Notice.find_all_by_store_id_and_types_and_status(params[:store_id].to_i,
      Notice::TYPES[:BIRTHDAY], Notice::STATUS[:NOMAL])
  end

  def material_types
    types = []
    Material::TYPES_NAMES.to_a.each_with_index{|item,idx|
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

  def current_user
    if cookies[:user_id]
      user = Staff.find cookies[:user_id]
    end
    user
  end

  def satisfy
    orders = Order.find(:all, :select => "is_pleased", :conditions => ["created_at > ? and created_at < ?",
        Time.mktime(Time.now.year, Time.now.mon-1, 1), Time.mktime(Time.now.year, Time.now.mon, 1)])
    un_pleased_size = 0
    orders.collect { |o| un_pleased_size += 1 if o.is_pleased == Order::IS_PLEASED[:BAD] }
    return orders.size == 0 ? 0 : (orders.size - un_pleased_size)*100/orders.size
  end
end
