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
    date = fee.pay_date.to_date
    (1..params[:fee][:share_month].to_i).each do |i|
      money = fee.amount.to_f/params[:fee][:share_month].to_i
      money_detail << MoneyDetail.new({:types=>MoneyDetail::TYPES[:FEE],:parent_id=>fee.id,:month=>date.strftime("%Y-%m"),:amount=>money})
      date = date.next_month
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
    p @fees = Fee.where(sql).select("date_format(created_at,'%Y-%m') date,types,round(ifnull(sum(amount/share_month),0),2) t_amount").group("types,date_format(created_at,'%Y-%m-%d')").order("date desc")
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
    if params[:rend].to_i == Category::TYPES[:OWNER]
      @customer = Customer.find(params[:customer_id])
      p @pay_orders = OrderPayType.joins(:order=>[:customer,:car_num]).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
        :"orders.store_id"=>params[:store_id],:"orders.customer_id"=>@customer.id).select("code,order_pay_types.price p_price,num,order_pay_types.id p_id,date_format(order_pay_types.created_at,'%Y-%m-%d %H:%m') time")
    else
      @customer = Supplier.find(params[:customer_id])
      p @pay_orders = MaterialOrder.where(:status=>MaterialOrder::STATUS[:no_pay],:store_id=>params[:store_id],:supplier_id=>params[:customer_id]).
        select("code,price p_price,id p_id,date_format(created_at,'%Y-%m-%d %H:%m') time,date_format(arrival_at,'%Y-%m-%d %H:%m') arrival,carrier")
    end
    @account = Account.where(:store_id=>params[:store_id],:supply_id=>@customer.id,:types=>params[:rend].to_i).first
    @defines = Category.where(:types=>params[:rend].to_i).inject({}){|h,s|h[s.id]=s.name;h} #加载付款类型
    @staffs = Staff.valid.where(:store_id=>params[:store_id]).inject({}){|h,s|h[s.id]=s.name;h}
  end

  def complete_account
    OrderPayType.transaction do
      @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
      @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
      if params[:pay_recieve].to_f > 0
        PayReceipt.create({:types=>params[:rend].to_i,:supply_id=>params[:customer_id],:month=>Time.now.strftime("%Y-%m"),
            :amount=>params[:pay_recieve],:store_id=>params[:store_id],:staff_id=>params[:staff_id],:category_id=>params[:pay_type]})
      end
      account = Account.where(:store_id=>params[:store_id],:supply_id=>params[:customer_id]).first
      account = Account.create({:types=>params[:rend].to_i,:supply_id=>params[:customer_id],:store_id=>params[:store_id]}) if account.nil?
      if params[:rend].to_i == Category::TYPES[:OWNER]
        sql = "orders.store_id=#{params[:store_id]} "
        if @start_time != "0"
          sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')>='#{@start_time}'"
        end
        if @end_time != "0"
          sql += " and date_format(order_pay_types.created_at,'%Y-%m-%d')<='#{@end_time}'"
        end
        OrderPayType.where(:id=>params[:p_ids]).update_all(:pay_status=>OrderPayType::PAY_STATUS[:COMPLETE])
        check_result =  check_account(params[:customer_id],params[:store_id],Time.now.strftime("%Y-%m"))
        price = OrderPayType.where(:id=>params[:p_ids]).map(&:price).inject(0){|n,p|n+p}
        #    if (params[:pay_recieve].to_f + account.balance - price)  #核对数据库中数据
        #      params[:left_account].to_f  #付款后计算的余额
        #  check_result[0] + account.left_amt - check_result[1]  #总的核实结果
        @pay_orders = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE]).
          where(sql).select("code,order_pay_types.price p_price,customer_id,car_num_id,date_format(order_pay_types.created_at,'%Y-%m-%d %H:%m') time").group_by{|i|i.customer_id}
        @customers = Customer.find(@pay_orders.keys).inject({}){|h,c|h[c.id]=c;h}
      else
        sql = "store_id=#{params[:store_id]} "
        if @start_time != "0"
          sql += " and date_format(created_at,'%Y-%m-%d')>='#{@start_time}'"
        end
        if @end_time != "0"
          sql += " and date_format(created_at,'%Y-%m-%d')<='#{@end_time}'"
        end
        MaterialOrder.where(:id=>params[:p_ids]).update_all(:status=>MaterialOrder::STATUS[:pay])
        @pay_orders = MaterialOrder.where(:status=>MaterialOrder::STATUS[:no_pay]).where(sql).select("code,price p_price,supplier_id,
    date_format(created_at,'%Y-%m-%d %H:%m') time").group_by{|i|i.supplier_id}
        suppliers = @pay_orders.keys
        suppliers.delete 0
        @customers = Supplier.find(suppliers).inject({0=>Supplier.new(:name=>"总部")}){|h,c|h[c.id]=c;h}
      end
      parm = {:pay_recieve =>params[:pay_recieve].to_f,:trade_amt=>params[:trade_amt],:balance=>params[:left_account] }
      account.update_attributes(parm)
      @account = Account.where(:supply_id=>@pay_orders.keys).inject({}){|h,c|h[c.supply_id]=c;h}
   
    end
  end

  def payable_account
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    p @pay_orders = MaterialOrder.where(:status=>MaterialOrder::STATUS[:no_pay]).where(sql).select("code,price p_price,supplier_id,
    date_format(created_at,'%Y-%m-%d %H:%m') time").group_by{|i|i.supplier_id}
    suppliers = @pay_orders.keys
    suppliers.delete 0
    @customers = Supplier.find(suppliers).inject({0=>Supplier.new(:name=>"总部")}){|h,c|h[c.id]=c;h}
    @account = Account.where(:supply_id=>suppliers).inject({}){|h,c|h[c.supply_id]=c;h}
    respond_to do |format|
      format.html
      format.js
    end
  end


  def manage_account
    @position = params[:position].nil? || params[:position] == "" ? Account::TYPES[:CUSTOMER] : params[:position].to_i
    sql = "accounts.store_id=#{params[:store_id]} "
    if params[:account_name] && params[:account_name] != "" && params[:account_name].length != 0
      sql +=  " and name like '%#{params[:account_name].strip.gsub(/[%_]/){|x| '\\' + x}}%'"
    end
    p @accounts = Account.joins("inner join customers c on c.id=accounts.supply_id").where(sql).select("c.name,c.group_name,accounts.*").group_by{|i|i.types}
    @accounts.merge!(Account.joins("inner join suppliers s on s.id=accounts.supply_id").where(sql).select("s.name,accounts.*").group_by{|i|i.types})
    respond_to do |format|
      format.html
      format.js
    end
  end

  def cost_price
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    @cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:good]).inject({}){|h,c|h[c.id]=c.name;h}
    sql = "orders.store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(orders.created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(orders.created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    if params[:prod_types] && params[:prod_types] != "" && params[:prod_types].length != 0
      sql += " and products.category_id=#{params[:prod_types]}"
    end
    @t_orders = Order.joins(:order_prod_relations=>{:product=>:category}).where(:"products.is_service"=>Product::PROD_TYPES[:PRODUCT],
      :"orders.status"=>Order::PRINT_CASH).where(sql).select("products.service_code p_code,products.name p_name,categories.name c_name,
      round(ifnull(sum(order_prod_relations.t_price),0),2) t_price,ifnull(sum(pro_num),1) t_num").group("product_id")
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def analysis_price
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    @cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:material]).inject({}){|h,c|h[c.id]=c.name;h}
    sql = "mat_out_orders.store_id=#{params[:store_id]} "
    if @start_time != "0"
      sql += " and date_format(mat_out_orders.created_at,'%Y-%m-%d')>='#{@start_time}'"
    end
    if @end_time != "0"
      sql += " and date_format(mat_out_orders.created_at,'%Y-%m-%d')<='#{@end_time}'"
    end
    if params[:prod_types] && params[:prod_types] != "" && params[:prod_types].length != 0
      sql += " and materials.category_id=#{params[:prod_types]}"
    end
    @t_orders =  MatOutOrder.joins(:material=>:category).where(:types=>MatOutOrder::TYPES_VALUE[:cost]).where(sql).select("materials.code p_code,
    materials.name p_name,categories.name c_name,round(ifnull(sum(mat_out_orders.price),0),2) t_price,ifnull(sum(mat_out_orders.material_num),1) t_num").group("material_id")
    respond_to do |format|
      format.html
      format.js
    end
  end

  def manage_assets
    @staffs = Staff.where(:store_id=>params[:store_id],:type_of_w=>Staff::N_COMPANY.keys).order('type_of_w').group_by{|i|i.type_of_w}
    @fixed_assets = FixedAsset.where(:store_id=>params[:store_id])
  end

  

end
