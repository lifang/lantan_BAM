#encoding: utf-8
class ComplaintsController < ApplicationController
  before_filter :sign?
  layout "complaint"
  require 'will_paginate/array'

  #投诉分类统计
  def index
    @complaint = Complaint.get_chart(params[:store_id])
    @complaint = Complaint.gchart(params[:store_id])  if @complaints.blank?
    @complaint = ChartImage.where("store_id=#{params[:store_id]} and types=#{ChartImage::TYPES[:COMPLAINT]}").order("created_at desc")[0]  if @complaint.nil?
    session[:created_at]=@complaint.nil? ? nil : @complaint.current_day.strftime("%Y-%m")
    session[:start_sex],session[:end_sex],session[:sex]=Time.now.beginning_of_month.strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d"),Complaint::SEX[:NONE] 
    @total_com = Complaint.show_types(params[:store_id],session[:start_sex],session[:end_sex],session[:sex])
    @size = ((@total_com.values.max.nil? ? 1 :@total_com.values.max)/10+1)*10#生成图表的y的坐标
  end

  #投诉分类查询
  def search
    session[:created_at]=nil
    session[:created_at]=params[:created_at]
    redirect_to "/stores/#{params[:store_id]}/complaints/search_list"
  end

  #投诉分类查询列表
  def search_list
    @complaint =Complaint.search_lis(params[:store_id],session[:created_at])
    @total_com = Complaint.show_types(params[:store_id],session[:start_sex],session[:end_sex],session[:sex])
    @size = ((@total_com.values.max.nil? ? 1 :@total_com.values.max)/10+1)*10#生成图表的y的坐标
    render 'index'
  end

  #投诉分类按时间和性别查询统计
  def search_time
    session[:start_sex],session[:end_sex],session[:sex],session[:end_name]=nil,nil,nil,nil
    session[:start_sex],session[:end_sex],session[:sex],session[:end_name]=params[:start_sex],params[:end_sex],params[:sex],params[:end_name]
    redirect_to "/stores/#{params[:store_id]}/complaints/date_list"
  end
  
  #投诉分类按时间和性别查询统计列表
  def date_list
    @complaint =Complaint.search_lis(params[:store_id],session[:created_at])
    @total_com = Complaint.show_types(params[:store_id],session[:start_sex],session[:end_sex],session[:sex],session[:end_name])
    @size = ((@total_com.values.max.nil? ? 1 :@total_com.values.max)/10+1)*10#生成图表的y的坐标
    render 'index'
  end

  #投诉详细页
  def show_detail
    session[:start_detail],session[:end_detail] =Time.now.beginning_of_month.strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d")
    total = Complaint.search_detail(params[:store_id],session[:start_detail],session[:end_detail])
    @complaint = total.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    time = Complaint::TIMELY_DAY
    non_time =total.inject(0){|num,complaint| 
      num +=1 if complaint.diff_time && (complaint.diff_time/60 < time ||(complaint.diff_time/60 == time && complaint.diff_time%60==0) );num }
    un_done = total.inject(0){|num,complaint| num +=1 if complaint.process_at;num}
    @staff_name ={}
    @complaint.each do |comp|
      @staff_name[comp.id]=Staff.where("id in (#{comp.staff_id_1},#{comp.staff_id_2})").map(&:name).join("、 ") if comp.staff_id_1 and comp.staff_id_2
    end
    @non =(non_time*100.0/total.size).round(1)
    @undo =((un_done)*100.0/total.size).round(1)
  end

  #投诉详细查询
  def detail_s
    session[:start_detail],session[:end_detail]=nil,nil
    session[:start_detail],session[:end_detail] =params[:start_detail],params[:end_detail]
    redirect_to "/stores/#{params[:store_id]}/complaints/detail_list"
  end
  
  #投诉详细查询列表
  def detail_list
    total = Complaint.search_detail(params[:store_id],session[:start_detail],session[:end_detail])
    time = Complaint::TIMELY_DAY
    non_time =total.inject(0){|num,complaint|num +=1 if complaint.diff_time && (complaint.diff_time/60 < time ||(complaint.diff_time/60 == time && complaint.diff_time%60==0));num }
    un_done = total.inject(0){|num,complaint| num +=1 if complaint.process_at;num}
    @complaint = total.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @staff_name ={}
    @complaint.each do |comp|
      @staff_name[comp.id]=Staff.where("id in (#{comp.staff_id_1},#{comp.staff_id_2})").map(&:name).join("、 ") if comp.staff_id_1 and comp.staff_id_2
    end
    @non =(non_time*100.0/total.size).round(1)
    @undo =((un_done)*100.0/total.size).round(1)
    render 'show_detail'
  end

  #满意度统计页
  def satisfy_degree
    @degree = Complaint.count_pleasant(params[:store_id])
    @degree = Complaint.degree_chart(params[:store_id])  if @degree.blank?
    @degree = ChartImage.where("store_id=#{params[:store_id]} and types=#{ChartImage::TYPES[:SATIFY]}").order("created_at desc")[0]  if @degree.nil?
    session[:degree]= @degree.nil? ? nil : @degree.current_day.strftime("%Y-%m")
    session[:start_degree],session[:end_degree],session[:sex_degree]=Time.now.beginning_of_month.strftime("%Y-%m-%d"),Time.now.strftime("%Y-%m-%d"),Complaint::SEX[:NONE]
    @total_com = Complaint.degree_day(params[:store_id],session[:start_degree],session[:end_degree],session[:sex_degree])
  end

  #满意度图标
  def degree_time
    session[:start_degree],session[:end_degree],session[:sex_degree],session[:c_name]=nil,nil,nil,nil
    session[:start_degree],session[:end_degree],session[:sex_degree],session[:c_name]=params[:start_degree],params[:end_degree],params[:sex],params[:c_name]
    redirect_to "/stores/#{params[:store_id]}/complaints/time_list"
  end
  
  #按照查询的日期生成满意度
  def time_list
    @degree =Complaint.degree_lis(params[:store_id],session[:degree])
    @total_com = Complaint.degree_day(params[:store_id],session[:start_degree],session[:end_degree],session[:sex_degree],session[:c_name])
    render 'satisfy_degree'
  end

  #满意度查询
  def search_degree
    session[:degree]=nil
    session[:degree]=params[:degree]
    redirect_to "/stores/#{params[:store_id]}/complaints/degree_list"
  end

  #满意度查询列表
  def degree_list
    @degree =Complaint.degree_lis(params[:store_id],session[:degree])
    @total_com = Complaint.degree_day(params[:store_id],session[:start_degree],session[:end_degree],session[:sex_degree])
    render 'satisfy_degree'
  end

  

  #客户-投诉-点击详细
  def complaint_detail
    @store = Store.find_by_id(params[:store_id])
    @complaint = @store.complaints.includes(:order).find_by_id(params[:id])
    @staff_names = Staff.where(:id => [@complaint.staff_id_1, @complaint.staff_id_2].compact).map(&:name).join(", ")
    @violation_rewards = ViolationReward.find_by_sql("select vr.*, s.name name from violation_rewards vr inner join staffs s on vr.staff_id = s.id where target_id = #{ @complaint.id}")
  end

  #客户消费统计
  def consumer_list
    @order_price = {}
    session[:list_start],session[:list_end],session[:list_prod],session[:list_sex],session[:list_year]=nil,nil,nil,nil,nil
    session[:list_fee],session[:list_model],session[:list_name]=nil,nil,nil
    complaints = Complaint.consumer_types(params[:store_id],1)
    @consumers = complaints.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @total_price = complaints.inject(0){|num,prod|num +(prod.price.nil? ? 0 : prod.price)}
    unless @consumers.blank?
      products = OrderProdRelation.find_by_sql("select opr.order_id, opr.pro_num, opr.price order_price, p.name p_name from order_prod_relations opr
   left join products p on p.id = opr.product_id where opr.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
      @order_prods = {}
      products.each { |p|
        @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p
      } if products.any?
      pcar_relations = CPcardRelation.find_by_sql("select cpr.order_id,1 pro_num, pc.price order_price, pc.name p_name from c_pcard_relations cpr
    inner join package_cards pc on pc.id = cpr.package_card_id where cpr.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
      pcar_relations.each { |p|
        @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p
      } if pcar_relations.any?
      scard_relations = CSvcRelation.find_by_sql("select cpr.order_id,1 pro_num, pc.price order_price, pc.name p_name from c_svc_relations cpr
    inner join sv_cards pc on pc.id = cpr.sv_card_id where cpr.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
      scard_relations.each { |p|
        @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p
      } if scard_relations.any?
    end
  end

  #消费客户查询
  def consumer_search
    session[:list_start],session[:list_end],session[:list_prod],session[:list_sex],session[:list_year]=nil,nil,nil,nil,nil
    session[:list_fee],session[:list_model],session[:list_name]=nil,nil,nil
    session[:list_start],session[:list_end],session[:list_prod],session[:list_sex]=params[:list_start],params[:list_end],params[:list_prod],params[:list_sex]
    session[:list_year],session[:list_fee],session[:list_model],session[:list_name]=params[:list_year],params[:list_fee],params[:list_model],params[:list_name]
    redirect_to "/stores/#{params[:store_id]}/complaints/con_list"
  end

  #客户消费统计查询
  def con_list
    @order_prods = {}
    @order_price = {}
    if session[:list_prod].nil? || session[:list_prod] =="" || session[:list_prod].length==0
      complaints =Complaint.consumer_types(params[:store_id],0,session[:list_start],session[:list_end],session[:list_sex],session[:list_model],session[:list_year],session[:list_name],session[:list_fee])
      @consumers = complaints.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
      unless @consumers.blank?
        products = OrderProdRelation.find_by_sql("select opr.order_id, opr.pro_num, opr.price order_price, p.name p_name from order_prod_relations opr
        left join products p on p.id = opr.product_id where opr.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
        @order_prods = {}
        products.each { |p|
          @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p
        } if products.any?
        pcar_relations = CPcardRelation.find_by_sql("select cpr.order_id,1 pro_num, pc.price order_price, pc.name p_name from c_pcard_relations cpr
        inner join package_cards pc on pc.id = cpr.package_card_id where cpr.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
        pcar_relations.each { |p|
          @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p
        } if pcar_relations.any?
        scard_relations = CSvcRelation.find_by_sql("select cpr.order_id,1 pro_num, pc.price order_price, pc.name p_name from c_svc_relations cpr
    inner join sv_cards pc on pc.id = cpr.sv_card_id where cpr.order_id in (#{@consumers.map(&:id).uniq.join(",")})")
        scard_relations.each { |p|
          @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p
        } if scard_relations.any?

      end
      @total_price = complaints.inject(0){|num,prod|num +(prod.price.nil? ? 0 : prod.price)}
    else
      sql ="select p.name p_name,o.price order_price,o.pro_num,o.order_id,o.total_price,p.id from products p inner join order_prod_relations o on o.product_id=p.id where p.types =#{session[:list_prod]}"
      proucts =Product.find_by_sql(sql)
      @consumers = []
      unless proucts.blank?
        complaints =Complaint.consumer_t(params[:store_id],proucts.map(&:order_id),session[:list_start],session[:list_end],session[:list_sex],session[:list_model],session[:list_year],session[:list_name],session[:list_fee])
        @consumers = complaints.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
        prices = {}
        unless @consumers.blank?
          prices =OrderPayType.find_by_sql("select sum(price) price,order_id,product_id from order_pay_types o where o.order_id in (#{complaints.map(&:id).join(",")}) and product_id in (#{proucts.map(&:id).uniq.join(",")})
          group by product_id,order_id").inject(Hash.new){|hash,pay|hash["#{pay.product_id}-#{pay.order_id}"].nil? ? hash["#{pay.product_id}-#{pay.order_id}"]=(pay.price.nil? ? 0 : pay.price) : hash["#{pay.product_id}-#{pay.order_id}"] += (pay.price.nil? ? 0 : pay.price);hash}
        end
        proucts.each { |p|
          @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p;
          @order_price[p.order_id].nil? ? @order_price[p.order_id] =(p.total_price.nil? ? 0:p.total_price)-(prices["#{p.id}-#{p.order_id}"].nil? ? 0 :prices["#{p.id}-#{p.order_id}"]) : @order_price[p.order_id]+= (p.total_price.nil? ? 0:p.total_price)-(prices["#{p.id}-#{p.order_id}"].nil? ? 0 : prices["#{p.id}-#{p.order_id}"])
        } if proucts.any?
        @total_price= complaints.inject(0){|total,prod|total += (@order_price[prod.id].nil? ? 0 : @order_price[prod.id])  }
      end
    end
    render "consumer_list"
  end

  def cost_price
    created,ended,types,store_id,session[:types] = params[:created],params[:ended],params[:types],params[:store_id],params[:types]
    session[:created]=created.nil? ? (Time.now - Constant::PRE_DAY.days).strftime("%Y-%m-%d") : created
    session[:ended] = ended.nil? ? Time.now.strftime("%Y-%m-%d") : ended
    m_condit,order_con = "mat_out_orders.store_id=#{store_id}","orders.store_id=#{store_id}"
    unless   created == "" || created.length == 0
      m_condit += "  and mat_out_orders.created_at >= '#{session[:created]}' "
      order_con += " and orders.created_at >= '#{session[:created]}'"
    end
    unless   ended == "" || ended.length == 0
      m_condit += " and mat_out_orders.created_at < '#{session[:ended]}' "
      order_con += " and orders.created_at < '#{session[:ended]}'"
    end
    order_con += " and is_service=#{Product::PROD_TYPES[:SERVICE]} and orders.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]})"
    order_con += " and products.id = #{types}" unless types.nil? || types == "" || types.length == 0
    t_orders = Order.joins(:order_prod_relations=>:product).joins("inner join prod_mat_relations p on p.product_id = products.id inner join
    materials m on m.id = p.material_id").select("sum(order_prod_relations.pro_num*m.price*p.material_num) total_price,
    orders.id,m.id m_id,orders.cons_staff_id_1,orders.cons_staff_id_2").where(order_con).group("id,m_id")
    @service = Product.where(:is_service =>Product::PROD_TYPES[:SERVICE],:store_id => store_id).inject(Hash.new){|hash,serv| hash[serv.id]=serv.name;hash}
    s_price = t_orders.inject(Hash.new){|hash,order|
      price = order.total_price.nil? ? 0 : order.total_price;hash[order.id].nil? ? hash[order.id]=price : hash[order.id] += price;hash}
    staff_ids = (t_orders.map(&:cons_staff_id_1) | t_orders.map(&:cons_staff_id_2)).uniq.compact
    s_orders = {}
    t_orders.each do |order|
      s_orders[order.cons_staff_id_1].nil? ? s_orders[order.cons_staff_id_1]=[order.id] : s_orders[order.cons_staff_id_1] << order.id
      s_orders[order.cons_staff_id_2].nil? ? s_orders[order.cons_staff_id_2]=[order.id] : s_orders[order.cons_staff_id_2] << order.id
    end
    staffs = Staff.find staff_ids
    w_orders = WorkOrder.find_all_by_order_id(t_orders.map(&:id).uniq.compact).inject(Hash.new){|hash,w_order|
      hash[w_order.order_id]=[w_order.gas_num,w_order.water_num];hash}
    m_condit += " and material_id in (#{t_orders.map(&:m_id).uniq.compact.join(',')})" unless t_orders.blank? || session[:types].nil?
    m_price = MatOutOrder.joins(:material).where(m_condit + " and mat_out_orders.types = #{MatOutOrder::TYPES_VALUE[:cost]}").
      select("staff_id,sum(material_num*mat_out_orders.price) sum").group("staff_id").inject(Hash.new){|hash,s| hash[s.staff_id] = s.sum;hash }
    infos = []
    staffs.each {|staff|
      gas_num,water_num,cost_price =0,0,m_price[staff.id].nil? ? 0 : m_price[staff.id]
      w_orders.select{|k,v|s_orders[staff.id].include? k}.values.each {|info| 
        gas_num += (info[0].nil? ? 0 : info[0]);water_num += (info[1].nil? ? 0 : info[1])}
      price = s_price.select{|k,v|s_orders[staff.id].include? k}.values.inject(0){|num,price| num+(price.nil? ? 0 : price)}
      infos << [staff.name,water_num,gas_num,cost_price,s_orders[staff.id].uniq.compact.length,price]
    }
    @s_infos = infos.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
  end


end
