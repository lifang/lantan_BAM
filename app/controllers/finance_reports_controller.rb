#encoding: utf-8
class FinanceReportsController < ApplicationController
  layout 'finance'
  require 'will_paginate/array'
  
  def index
    Station.turn_old_to_new
    @title = "主营收入"
    @category = Category.where(:store_id=>params[:store_id],:types=>Category::DATA_TYPES).inject({}){|h,c|h[c.id]=c.name;h}
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql,orders,del_ids = "1=1",[],[]
    if @start_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    if params[:customer_name]
      sql += " and customers.name like '%#{params[:customer_name].gsub(/[%_]/){|x| '\\' + x}}%'"
    end
    if params[:category_id]
      sql += " and products.category_id=#{params[:category_id]}"
      p_orders = Order.joins([:car_num,:customer,:order_prod_relations =>:product]).select("orders.*,customers.mobilephone phone,
     customers.name c_name,customers.group_name,car_nums.num c_num,customers.id c_id").where(:status=>Order::OVER_CASH,:store_id=>
          params[:store_id]).where(sql).order("orders.updated_at desc")
    else
      p_orders = Order.joins([:car_num,:customer]).select("orders.*,customers.mobilephone phone,customers.name c_name,customers.group_name,
     car_nums.num c_num,customers.id c_id").where(:status=>Order::OVER_CASH,:store_id=>params[:store_id]).where(sql).order("orders.updated_at desc")
      del_ids = CSvcRelation.joins(:sv_card).where(:"sv_cards.types"=>SvCard::FAVOR[:SAVE],:"sv_cards.store_id"=>params[:store_id]).map(&:order_id)
      del_ids << CPcardRelation.joins(:package_card).where(:"package_cards.store_id"=>params[:store_id]).map(&:order_id)
    end
    p_types = params[:pay_type].nil? ? OrderPayType::FINCANCE_TYPES.keys : params[:pay_type].split(",").inject([]){|arr,type|arr << type.to_i}
    order_types = OrderPayType.pay_order_types(p_orders.map(&:id))
    p_orders.each do |p_order|
      if order_types[p_order.id]
        o_types = order_types[p_order.id].keys
        orders <<  p_order if (o_types-p_types).length != o_types.length and !del_ids.flatten.include? p_order.id
      end
    end
    unless orders.blank?
      @pays = OrderPayType.search_pay_types(orders.map(&:id))
      @orders = orders.paginate(:page=>params[:page],:per_page=>Constant::LITE_PAGE)
      @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
      @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
      staff_ids = (@orders.map(&:cons_staff_id_1)|@orders.map(&:cons_staff_id_2)|@orders.map(&:front_staff_id)).compact.uniq
      staff_ids.delete 0
      @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    else
      @pays,@orders = {},[]
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def revenue_report
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "1=1"
    if @start_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(orders.updated_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    @p_orders = Order.joins([:car_num,:customer,:order_prod_relations=>:product]).joins("left join work_orders w on w.order_id=orders.id").
      select("orders.*,customers.mobilephone phone,customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,
      customers.id c_id,products.is_service").where(:status=>Order::PRINT_CASH,:store_id=>params[:store_id]).where(sql).order("orders.updated_at desc")
    @pays = OrderPayType.search_pay_types(@p_orders.map(&:id))
    @pay_types = OrderPayType.pay_order_types(@p_orders.map(&:id))
    @order_price = @p_orders.inject({}){|h,p|h[p.is_service].nil? ? h[p.is_service]={p.id=>p.price} : h[p.is_service][p.id]=p.price;h}
    @orders = @p_orders.paginate(:page=>params[:page],:per_page=>Constant::LITE_PAGE)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def fee_manage
    @staffs = Staff.where(:store_id=>params[:store_id],:type_of_w=>Staff::N_COMPANY.keys).order('type_of_w').group_by{|i|i.type_of_w}
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    @position = params[:position].nil? || params[:position] == "" ? 0 : params[:position].to_i
    sql = "store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    p @fees = Fee.where(sql).group_by{|i|i.types}
    @customers = Staff.find(@fees.values.flatten.map(&:operate_staffid)).inject({}){|h,c|h[c.id]=c.name;h}
    respond_to do |format|
      format.html
      format.js
    end
  end
 

  def create
    fee = Fee.create(params[:fee].merge({:store_id=>params[:store_id]}))
    money_detail = []
    if params[:fee][:share_month]
      date = fee.pay_date.to_date
      (1..params[:fee][:share_month].to_i).each do |i|
        money = fee.amount.to_f/params[:fee][:share_month].to_i
        money_detail << MoneyDetail.new({:types=>MoneyDetail::TYPES[:FEE],:parent_id=>fee.id,:month=>date.strftime("%Y-%m"),:amount=>money})
        date = date.next_month
      end
    else
      money_detail << MoneyDetail.new({:types=>MoneyDetail::TYPES[:FEE],:parent_id=>fee.id,:month=>fee.pay_date.strftime("%Y-%m"),:amount=>fee.amount})
    end
    MoneyDetail.import money_detail
    redirect_to request.referer
  end

  def show_fee
    @fee = Fee.find(params[:fee_id])
    @position = params[:position].to_i
    @customers = Staff.find([@fee.create_staffid,@fee.operate_staffid]).inject({}){|h,c|h[c.id]=c.name;h}
  end

  def fee_report
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    p @fees = Fee.where(sql).select("date_format(created_at,'%Y-%m-%d') date,types,sum(amount) t_amount").group("types,date_format(created_at,'%Y-%m-%d')").order("date desc")
  end


  def pay_account
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "orders.store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    p @pay_orders = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE]).
      where(sql).select("code,order_pay_types.price p_price,customer_id,car_num_id,date_format(order_pay_types.created_at,'%Y-%m-%d %H:%m') time").group_by{|i|i.customer_id}
    @customers = Customer.find(@pay_orders.keys).inject({}){|h,c|h[c.id]=c;h}
    @account = Account.where(:supply_id=>@pay_orders.keys).inject({}){|h,c|h[c.supply_id]=c;h}
    respond_to do |format|
      format.html
      format.js
    end
  end

  #加载应收款数据
  def load_account
    @customer = Customer.find(params[:customer_id])
    p @pay_orders = OrderPayType.joins(:order=>[:customer,:car_num]).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
      :"orders.store_id"=>params[:store_id],:"orders.customer_id"=>@customer.id).select("code,order_pay_types.price p_price,num,order_pay_types.id p_id,date_format(order_pay_types.created_at,'%Y-%m-%d %H:%m') time")
    @account = Account.where(:store_id=>params[:store_id],:supply_id=>@customer.id,:types=>Account::TYPES[:CUSTOMER]).first
    @staffs = Staff.valid.where(:store_id=>params[:store_id]).inject({}){|h,s|h[s.id]=s.name;h}
    @defines = PaymentDefine.where(:store_id=>params[:store_id]).inject({}){|h,s|h[s.id]=s.description;h}
  end

  def complete_account
    OrderPayType.transaction do
      OrderPayType.where(:id=>params[:p_ids]).update_all(:pay_status=>OrderPayType::PAY_STATUS[:COMPLETE])
      if params[:pay_recieve].to_f > 0
        PayReceipt.create({:types=>Account::TYPES[:CUSTOMER],:supply_id=>params[:customer_id],:month=>Time.now.strftime("%Y-%m"),
            :amount=>params[:pay_recieve],:store_id=>params[:store_id],:staff_id=>params[:staff_id],:payment_define_id=>params[:pay_type]})
      end
      account = Account.where(:store_id=>params[:store_id],:supply_id=>params[:customer_id]).first
      account = Account.create({:types=>Account::TYPES[:CUSTOMER],:supply_id=>params[:customer_id],:store_id=>params[:store_id]}) if account.nil?
      check_result =  check_account(params[:customer_id],params[:store_id],Time.now.strftime("%Y-%m"))
      price = OrderPayType.where(:id=>params[:p_ids]).map(&:price).inject(0){|n,p|n+p}
      #    if (params[:pay_recieve].to_f + account.balance - price)  #核对数据库中数据
      #      params[:left_account].to_f  #付款后计算的余额
      #  check_result[0] + account.left_amt - check_result[1]  #总的核实结果
      parm = {:pay_recieve =>params[:pay_recieve].to_f,:trade_amt=>params[:trade_amt],:balance=>params[:left_account] }
      account.update_attributes(parm)
      @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
      @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
      sql = "orders.store_id=#{params[:store_id]} "
      if @start_time != "0"
        sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')>='#{@start_time}'"
      end
      if @end_time != "0"
        sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')<='#{@end_time}'"
      end
      p @pay_orders = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE]).
        where(sql).select("code,order_pay_types.price p_price,customer_id,car_num_id").group_by{|i|i.customer_id}
      @customers = Customer.find(@pay_orders.keys).inject({}){|h,c|h[c.id]=c;h}
      #    end
    end
  end

  def payable_account
    
  end

  def manage_account
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "orders.store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    @accounts = Account.where(:store_id=>params[:store_id]).group_by{|i|i.types}
    @names = {Account::TYPES[:CUSTOMER]=>{},Account::TYPES[:SUPPLY]=>{}}
    unless @accounts[Account::TYPES[:CUSTOMER]].nil?
      @names[Account::TYPES[:CUSTOMER]] = Customer.find(@accounts[Account::TYPES[:CUSTOMER]].map(&:supply_id)).inject({}){|h,c|h[c.id]=c.name;h}
    end
    unless @accounts[Account::TYPES[:SUPPLY]].nil?
      @names[Account::TYPES[:SUPPLY]] = Supply.find(@accounts[Account::TYPES[:SUPPLY]].map(&:supply_id)).inject({}){|h,c|h[c.id]=c.name;h}
    end
  end

end
