#encoding: utf-8
require "uri"
class CustomersController < ApplicationController
  before_filter :sign?
  include RemotePaginateHelper
  layout "customer", :except => [:print_orders,:operate_order]
  require 'will_paginate/array'
  before_filter :customer_tips, :except => [:get_car_brands]

  def index
    session[:c_property] = nil
    session[:car_num] = nil
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:name] = nil
    session[:phone] = nil
    session[:c_sex] = nil
    session[:is_vip] = nil

    @store = Store.find_by_id(params[:store_id]) || not_found
    @customers = Customer.search_customer(params[:c_property], params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone], params[:c_sex], params[:is_vip], params[:page], params[:store_id].to_i) if @store
    @car_nums = Customer.customer_car_num(@customers) if @customers
  end

  def search
    session[:c_property] = params[:c_property]
    session[:car_num] = params[:car_num]
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:name] = params[:name]
    session[:phone] = params[:phone]
    session[:c_sex] = params[:c_sex]
    session[:is_vip] = params[:is_vip]
    redirect_to "/stores/#{params[:store_id]}/customers/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Customer.search_customer(session[:c_property], session[:car_num], session[:started_at], session[:ended_at],
      session[:name], session[:phone], session[:c_sex], session[:is_vip], params[:page], params[:store_id].to_i) if @store
    @car_nums = Customer.customer_car_num(@customers) if @customers
    render "index"
  end

  def destroy
    @customer = Customer.find(params[:id].to_i)
    @customer.update_attributes(:status => Customer::STATUS[:DELETED])
    flash[:notice] = "删除成功。"
    redirect_to request.referer
  end

  def create
    if params[:new_name] and params[:mobilephone]
      customer = Customer.where(:status=>Customer::STATUS[:NOMAL],:mobilephone=>params[:mobilephone].strip,
        :store_id=>params[:store_id].to_i).first
      if customer
        flash[:notice] = "手机号码#{params[:mobilephone].strip}在系统中已经存在。"
        unless params[:selected_cars].blank?
          params[:selected_cars].each do |sc|
            car_num = sc.split("-")[0]
            car_model = sc.split("-")[1].to_i
            buy_year = sc.split("-")[2].to_i
            car_num_record = CarNum.find_by_num(car_num)
            if car_num_record
              cnr = CustomerNumRelation.find_by_car_num_id_and_customer_id(car_num_record.id, customer.id)
              unless cnr
                CustomerNumRelation.delete_all(["car_num_id = ?", car_num_record.id])
                CustomerNumRelation.create(:car_num_id => car_num_record.id, :customer_id => customer.id)
              end
            else
              car_num_record = CarNum.create(:num => car_num, :buy_year => buy_year, :car_model_id => car_model)
              CustomerNumRelation.create(:car_num_id => car_num_record.id, :customer_id => customer.id)
            end
          end
        end
      else
        property = params[:property].to_i
        name = params[:new_name].strip
        group_name = params[:group_name].nil? ? nil : params[:group_name].strip
        allowed_debts = params[:allowed_debts].to_i
        debts_money = params[:debts_money].nil? ? nil : params[:debts_money].to_f
        check_type = params[:check_type].nil? ? nil : params[:check_type].to_i
        check_time = params[:check_time_month].nil? ? (params[:check_time_week].nil? ? nil : params[:check_time_week].to_i) : params[:check_time_month].to_i
        new_customer = Customer.create(:name => name, :mobilephone => params[:mobilephone].strip, :other_way => params[:other_way].strip,
          :sex => params[:sex], :birthday => params[:birthday].strip, :address => params[:address].strip,
          :status => Customer::STATUS[:NOMAL], :types => Customer::TYPES[:NORMAL], :username => name, :property => property,
          :group_name => group_name, :allowed_debts => allowed_debts, :debts_money => debts_money, :check_type => check_type,
          :check_time => check_time,:store_id=>params[:store_id],:is_vip => params[:is_vip])
        new_customer.encrypt_password
        new_customer.save
        unless params[:selected_cars].blank?
          params[:selected_cars].each do |sc|
            car_num = sc.split("-")[0]
            car_model = sc.split("-")[1].to_i
            buy_year = sc.split("-")[2].to_i
            car_num_record = CarNum.find_by_num(car_num)
            if car_num_record
              CustomerNumRelation.delete_all(["car_num_id = ?", car_num_record.id])
              CustomerNumRelation.create(:car_num_id => car_num_record.id, :customer_id => new_customer.id)
            else
              car_num_record = CarNum.create(:num => car_num, :buy_year => buy_year, :car_model_id => car_model)
              CustomerNumRelation.create(:car_num_id => car_num_record.id, :customer_id => new_customer.id)
            end
          end
        end
        flash[:notice] = "客户信息创建成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def update
    if params[:new_name] and params[:mobilephone]
      customer = Customer.find(params[:id].to_i)
      mobile_c = Customer.where(:status=>Customer::STATUS[:NOMAL],:mobilephone=>params[:mobilephone].strip,
        :store_id=>params[:store_id].to_i).first
      if mobile_c and mobile_c.id != customer.id
        flash[:notice] = "手机号码#{params[:mobilephone].strip}在系统中已经存在。"
      else
        customer.update_attributes(:name => params[:new_name].strip, :mobilephone => params[:mobilephone].strip,
          :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
          :address => params[:address], :property => params[:edit_property].to_i,
          :group_name => params[:edit_property].to_i==Customer::PROPERTY[:PERSONAL] ? nil : params[:edit_group_name].strip,
          :allowed_debts => params[:edit_allowed_debts].to_i,:is_vip => params[:is_vip],
          :debts_money => params[:edit_allowed_debts].to_i==Customer::ALLOWED_DEBTS[:NO] ? nil : params[:edit_debts_money].to_f,
          :check_type => params[:edit_check_type].nil? ? nil : params[:edit_check_type].to_i,
          :check_time => params[:edit_check_time_month].nil? ? (params[:edit_check_time_week].nil? ? nil : params[:edit_check_time_week].to_i) :  params[:edit_check_time_month].to_i)
        flash[:notice] = "客户信息更新成功。"
      end
    end
    redirect_to request.referer
  end

  def customer_mark
    customer = Customer.find(params[:c_customer_id].to_i)
    customer.update_attributes(:mark => params[:mark].strip) if params[:mark]
    flash[:notice] = "备注成功。"
    redirect_to request.referer
  end

  def single_send_message
    unless params[:content].strip.empty? or params[:m_customer_id].nil?
      MessageRecord.transaction do
        message_record = MessageRecord.create(:store_id => params[:store_id].to_i, :content => params[:content].strip,
          :status => MessageRecord::STATUS[:SENDED], :send_at => Time.now)
        customer = Customer.find(params[:m_customer_id].to_i)
        content = params[:content].strip.gsub("%name%", customer.name).gsub(" ", "")
        SendMessage.create(:message_record_id => message_record.id, :customer_id => customer.id,
          :content => content, :phone => customer.mobilephone,
          :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED])
        begin
          message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{customer.mobilephone}&Content=#{URI.escape(content)}&Exno=0"
          create_get_http(Constant::MESSAGE_URL, message_route)
        rescue
          flash[:notice] = "短信通道忙碌，请稍后重试。"
        end
        flash[:notice] = "短信发送成功。"
      end
    end
    redirect_to request.referer
  end

  def show
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @car_nums = CarNum.find_by_sql(["select c.id c_id, c.num, c.distance distance, cb.name b_name, cm.name m_name, cb.id b_id, cr.customer_id,
        cm.id m_id, c.buy_year,cb.capital_id
        from car_nums c left join car_models cm on cm.id = c.car_model_id
        left join car_brands cb on cb.id = cm.car_brand_id
        inner join customer_num_relations cr on cr.car_num_id = c.id
        where cr.customer_id = ?", @customer.id])
    order_page = params[:rev_page] ? params[:rev_page] : 1
    @orders = Order.one_customer_orders(Order::PRINT_CASH.join(','), params[:store_id].to_i, @customer.id, 10, order_page)
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, Constant::PER_PAGE, 1)
    comp_page = params[:comp_page] ? params[:comp_page] : 1
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, Constant::PER_PAGE, comp_page)
    svc_card_records_method(@customer.id)  #储值卡记录
    p_card = @customer.pcard_records(params[:store_id])
    @c_pcard_relations = p_card[1].paginate(:page => params[:page] || 1, :per_page => Constant::PER_PAGE) if p_card[1] #套餐卡记录
    @already_used_count = p_card[0]
  end
  
  def order_prods
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @orders = Order.one_customer_orders(Order::PRINT_CASH.join(','), params[:store_id].to_i, @customer.id, 10, params[:page])
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    respond_to do |format|
      format.js
    end
  end

  def sav_card_records
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    svc_card_records_method(@customer.id)
  end

  def pc_card_records
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @c_pcard_relations = @customer.pc_card_records_method(params[:store_id])[1].paginate(:page => params[:page] || 1, :per_page => Constant::PER_PAGE) if @customer.pc_card_records_method(params[:store_id])[1]  #套餐卡记录
    @already_used_count = @customer.pc_card_records_method(params[:store_id])[0]
  end

  def revisits
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, 10, params[:page])
    respond_to do |format|
      format.js
    end
  end

  def complaints
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, 10, params[:page])
    respond_to do |format|
      format.js
    end
  end

  def edit_car_num
    car_num_id = params[:id].split("_")[1].to_i
    customer_id = params[:id].split("_")[0]
    current_car_num = CarNum.find_by_id(car_num_id)
    distance = params["car_distance_#{car_num_id}"].to_i
    car_num = CarNum.find_by_num(params["car_num_#{car_num_id}"].strip)
    if car_num.nil? or car_num.id == current_car_num.id
      current_car_num.update_attributes(:num => params["car_num_#{car_num_id}"].strip,
        :buy_year => params["buy_year_#{car_num_id}"].to_i, :car_model_id => params["car_models_#{car_num_id}"].to_i,
        :distance => distance)
    else
      CustomerNumRelation.delete_all(["car_num_id = ?", car_num.id])
      CustomerNumRelation.create(:car_num_id => car_num.id, :customer_id => customer_id.to_i)
    end
    flash[:notice] = "车牌号码信息修改成功。"
    redirect_to "/stores/#{params["store_id_#{car_num_id}"]}/customers/#{customer_id}"
  end

  def get_car_brands
    respond_to do |format|
      format.json {
        render :json => CarBrand.get_brand_by_capital(params[:capital_id].to_i)
      }
    end
  end

  def get_car_models
    respond_to do |format|
      format.json {
        render :json => CarModel.get_model_by_brand(params[:brand_id].to_i)
      }
    end
  end

  def check_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    respond_to do |format|
      format.json {
        render :json => {:is_has => car_num.nil?}
      }
    end
  end

  def check_e_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    is_has = (car_num.nil? or (!car_num.nil? and (car_num.id == params[:car_num_id].to_i))) ? true : false
    respond_to do |format|
      format.json {
        render :json => {:is_has => is_has}
      }
    end
  end

  def delete_car_num
    ids = params[:id].split("_")
    customer_num_relation = CustomerNumRelation.find_by_car_num_id_and_customer_id(ids[0], ids[1])
    customer_num_relation.destroy
    flash[:notice] = "删除成功。"
    redirect_to request.referer
  end

  def show_revisit_detail    #显示回访详情
    @revisit = Revisit.find_by_id(params[:r_id].to_i)
    respond_to do |format|
      format.js
    end
  end

  def print_orders
    @orders = Order.find(params[:ids].split(","))
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
  end

  def return_order
    @order = Order.find(params[:o_id])
    @product_hash = OrderProdRelation.s_order_products(@order.id)
    @staffs = Staff.find([@order.try(:front_staff_id),@order.try(:cons_staff_id_1),@order.try(:cons_staff_id_2)]).inject(Hash.new){
      |hash,staff| hash[staff.id] = staff.name;hash
    }
  end

  def operate_order
    params[:types].split(",").each {|types|
      params[:"#{types}"].split(",").each do |type_id|
        m_model = types.split("#")
        model_name =  m_model[1] == "service" ? "product" : m_model[1]
        eval(m_model[0].split(".")[0].split("_").inject(String.new){|str,name| str + name.capitalize}).where({:order_id=>params[:order_id],
            :"#{model_name}_id"=> type_id}).first.update_attributes(:return_types=>Order::IS_RETURN[:YES])
      end }
    order = Order.find(params[:order_id])
    order.update_attributes(:return_reason=>params[:reason],:return_types=>Order::IS_RETURN[:YES],:price => (order.price.nil? ? 0 : order.price) - params[:account].to_f,
      :return_fee => params[:account].to_f,:return_direct => params[:direct],:return_staff_id =>cookies[:user_id])
    materials = {}
    if  params[:types].index("product")
      prod_nums = OrderProdRelation.where("order_id= #{order.id} and product_id in (#{params[:"order_prod_relation#product"]})").inject(Hash.new) {|hash,prod|
        hash[prod.product_id] = prod.pro_num;hash
      }
      ProdMatRelation.where("product_id in (#{params[:"order_prod_relation#product"]})").each{|mat|
        materials[mat.material_id].nil? ?  materials[mat.material_id] = mat.material_num*prod_nums[mat.product_id] : materials[mat.material_id] += mat.material_num*prod_nums[mat.product_id]
      }
    end
    if  params[:types].index("package_card")
      PcardMaterialRelation.where("package_card_id in (#{params[:"c_pcard_relation#package_card"]})").each{|mat|
        materials[mat.material_id].nil? ?  materials[mat.material_id] = mat.material_num : materials[mat.material_id] += mat.material_num
      }
      CPcardRelation.where("order_id = #{params[:order_id]} and package_card_id in (#{params[:"c_pcard_relation#package_card"]})").each {|card| card.update_attributes(:status=>PackageCard::STAT[:INVALID])}
    end
    if   params[:types].index("sv_card")
      CSvcRelation.where("order_id = #{params[:order_id]} and sv_card_id in (#{params[:"c_svc_relation#sv_card"]})").each {|card| card.update_attributes(:status=>CSvcRelation::STATUS[:invalid])}
    end
    if params[:direct].to_i == Order::O_RETURN[:REUSE]
      Material.find(materials.keys).each {|mat| mat.update_attributes(:storage => mat.storage+ materials[mat.id])}
    else
      materials.each {|k,v|MaterialLoss.create(:loss_num=>v,:staff_id => cookies[:user_id],:store_id=>order.store_id,:material_id => k)}
    end
    render :json =>{:msg=>order.code}
  end

  def add_car_get_datas #添加车辆 查找
    @type = params[:type].to_i
    id = params[:id].to_i
    if @type==0
      @brands = CarBrand.where(["capital_id = ?", id])
    elsif @type==1
      @models = CarModel.where(["car_brand_id= ?", id])
    end
  end

  def add_car #添加车牌
    cid = params[:add_car_cus_id].to_i
    buy_year = params[:add_car_buy_year].to_i
    car_num = params[:add_car_num].strip
    car_model = params[:add_car_models].to_i
    distance = params[:add_car_distance].to_i
    car_num_record = CarNum.find_by_num(car_num)
    if car_num_record
      cnr = CustomerNumRelation.find_by_car_num_id(car_num_record.id)
      if cnr and cnr.customer_id != cid
        cnr.update_attribute("customer_id", cid)
        car_num_record.update_attributes(:car_model_id => car_model, :buy_year => buy_year, :distance => distance)
        flash[:notice] = "车牌号码为"+car_num+"的车辆已关联到当前客户名下!"
      elsif cnr and cnr.customer_id == cid
        flash[:notice] = "添加失败,该客户已关联该车辆!"
      else
        car_num_record.update_attributes(:car_model_id => car_model, :buy_year => buy_year, :distance => distance)
        CustomerNumRelation.create(:customer_id => cid, :car_num_id => car_num_record.id)
        flash[:notice] = "添加成功!"
      end
    else
      new_num_record = CarNum.create(:num => car_num, :car_model_id => car_model, :buy_year => buy_year, :distance => distance)
      CustomerNumRelation.create(:customer_id => cid, :car_num_id => new_num_record.id)
      flash[:notice] = "添加成功!"
    end
    redirect_to "/stores/#{params[:store_id]}/customers/#{cid}"
  end
  private
  
  def svc_card_records_method(customer_id)
    #储值卡记录
    @svcard_records = SvcardUseRecord.paginate_by_sql(["select sur.*,sc.name sc_name  from svcard_use_records sur
      inner join c_svc_relations csr on csr.id = sur.c_svc_relation_id inner join sv_cards sc on csr.sv_card_id = sc.id
    where csr.customer_id = ? and csr.status = 1 order by sur.created_at desc", customer_id], :page => params[:page],
      :per_page => Constant::PER_PAGE)
    @srs = @svcard_records.group_by{|sr|sr.c_svc_relation_id} if @svcard_records
  end

  
end
