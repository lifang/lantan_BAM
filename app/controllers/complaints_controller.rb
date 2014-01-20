#encoding: utf-8
class ComplaintsController < ApplicationController
  before_filter :sign?
  layout "complaint"
  require 'will_paginate/array'

  #投诉分类统计
  def index    
    @store_id = params[:store_id].to_i
    @comp_month = params[:comp_month].nil? ? DateTime.now.months_ago(1).strftime("%Y-%m") : params[:comp_month]
    @div_name = params[:div_name].nil? ? nil :  params[:div_name]
    @comp_type = params[:comp_type].nil? || params[:comp_type].to_i ==0 ? 1 : params[:comp_type].to_i
    @plea_type = params[:plea_type].nil? || params[:plea_type].to_i==0 ? 1 : params[:plea_type].to_i
    @plea_start = params[:plea_start].nil? ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:plea_start]
    @plea_end = params[:plea_end].nil? ? Time.now.strftime("%Y-%m-%d") : params[:plea_end]
    comp_sql = "select c.reason,c.remark,c.types,c.status,c.process_at,c.created_at,c.is_violation,c.img_url,c.c_feedback_suggestion,
     c.code ccode,o.id,o.code ocode,cus.name cname,cus.mobilephone cphone,cn.num cnum,s1.name sname1, s2.name sname2,
     d1.name dname1,d2.name dname2
     from complaints c inner join orders o on c.order_id=o.id
     left join customers cus on o.customer_id=cus.id
     left join car_nums cn on o.car_num_id=cn.id
     left join staffs s1 on c.staff_id_1=s1.id
     left join staffs s2 on c.staff_id_2=s2.id
     left join departments z1 on s1.department_id=z1.id
     left join departments d1 on z1.dpt_id=d1.id
     left join departments z2 on s2.department_id=z2.id
     left join departments d2 on z2.dpt_id=d2.id
     where DATE_FORMAT(c.created_at,'%Y-%m')=? and c.store_id=?"
    case @comp_type
    when 1
      comp_sql += " and (c.types is null or c.types in (?))"
      cstatus = [0,1,2,3,4,5]
    when 2
      comp_sql += " and c.types in (?)"
      cstatus = [2]
    when 3
      comp_sql += " and c.types in (?)"
      cstatus = [1]
    when 4
      comp_sql += " and c.types in (?)"
      cstatus = [0,3,4,5]
    end
    comp_sql += " order by c.created_at desc"
    @complaints = Complaint.paginate_by_sql([comp_sql, @comp_month, @store_id, cstatus],
      :page => params[:page],:per_page => Constant::PER_PAGE) if @div_name.nil? || @div_name.eql?("s_div")
    plea_sql = ["select o.code,o.is_pleased,o.types,o.created_at,cus.name,cn.num
      from orders o left join customers cus on o.customer_id=cus.id
      left join car_nums cn on o.car_num_id=cn.id
      where DATE_FORMAT(o.created_at,'%Y-%m-%d')>=? and DATE_FORMAT(o.created_at,'%Y-%m-%d')<=?
      and o.store_id=? and o.status in (?)",@plea_start, @plea_end, @store_id, [Order::STATUS[:BEEN_PAYMENT],Order::STATUS[:FINISHED]]]
    unless @plea_type==1
      type = @plea_type==2 ? Order::TYPES[:PRODUCT] : Order::TYPES[:SERVICE]
      plea_sql[0] += " and o.types=?"
      plea_sql << type
    end
    plea_sql[0] += " order by o.created_at desc"
    pleaseds = Order.find_by_sql(plea_sql) if  @div_name.nil? || @div_name.eql?("p_div")
    unpleased,normal,good,nice = 0,0,0,0
    plea_hash = pleaseds.inject({}){|h,p|
      case p.is_pleased.to_i
      when 0
        unpleased += 1
        h[:unpleased] = unpleased
      when 1
        normal += 1
        h[:normal] = normal
      when 2
        good += 1
        h[:good] = good
      when 3
        nice += 1
        h[:nice] = nice
      end;
      h
    } if pleaseds
    plea_hash[:total] = pleaseds.length if pleaseds
    @plea_hash = plea_hash if plea_hash
    @pleaseds = pleaseds.paginate(:page => params[:page], :per_page => Constant::PER_PAGE) if pleaseds
    respond_to do |f|
      f.html
      f.js
    end
  end

  def meta_analysis
    @store_id = params[:store_id].to_i
    flag = params[:flag]
    if flag.nil? || flag.to_i==0
      #客户数量
      customers = Customer.find_by_sql(["select c.id,c.sex,c.property,c.allowed_debts from customer_store_relations csr inner join customers c
      on csr.customer_id=c.id where csr.store_id=? and c.status=?", @store_id, Customer::STATUS[:NOMAL]])
      @single_cus = 0
      @group_cus = 0
      @allowed_debts = 0
      @unallowed_dents = 0
      @male = 0
      @female = 0
      customers.each do |c|
        if c.property.to_i == 0
          @single_cus += 1
          if !c.sex.nil? && c.sex==true
            @male += 1
          elsif !c.sex.nil? && c.sex==false
            @female += 1
          end
        elsif c.property.to_i == 1
          @group_cus += 1
          if c.allowed_debts.to_i == Customer::ALLOWED_DEBTS[:NO]
            @unallowed_dents += 1
          elsif c.allowed_debts.to_i == Customer::ALLOWED_DEBTS[:YES]
            @allowed_debts += 1
          end
        end
      end

      #车辆品牌数量
      @brands = CustomerNumRelation.find_by_sql(["select cb.id,cb.name,sum(cb.id) sum from customer_num_relations cnr
        inner join car_nums cn on cnr.car_num_id=cn.id
        inner join car_models cm on cn.car_model_id=cm.id
        inner join car_brands cb on cm.car_brand_id=cb.id
        where cnr.customer_id in (?) group by cb.id order by sum desc", customers.map(&:id).uniq]) if customers.map(&:id).any?
      @other = @brands[4..@brands.length-1].inject(0){|i,b| i += b.sum.to_i;i} if @brands && @brands.length > 4

      #消费金额
      orders = Order.find_by_sql(["select sum(o.price) sum from customers c left join orders o on c.id=o.customer_id
      and o.status in (?) and o.store_id=? where c.id in (?) group by c.id",
          [Order::STATUS[:BEEN_PAYMENT], Order::STATUS[:FINISHED]],
          @store_id, customers.map(&:id).uniq]) if customers.map(&:id).any?
      @order_lv1, @order_lv2, @order_lv3, @order_lv4, @order_lv5, @order_lv6 = 0, 0, 0, 0, 0, 0
      orders.each do |o|
        price = o.sum.to_i
        if price >=0 and price < 100
          @order_lv1 += 1
        elsif price >= 100 and price < 500
          @order_lv2 += 1
        elsif price >= 500 and price < 1000
          @order_lv3 += 1
        elsif price >= 1000 and price < 2000
          @order_lv4 += 1
        elsif price >= 2000 and price < 5000
          @order_lv5 += 1
        elsif price >= 5000
          @order_lv6 += 1
        end
      end if orders

      #最近消费
      @cons_current_day = Order.find_by_sql(["select count(o.id) count from orders o where o.status in (?) and o.store_id=? and
        DATE_FORMAT(o.created_at,'%Y-%m-%d')=?", [Order::STATUS[:BEEN_PAYMENT], Order::STATUS[:FINISHED]], @store_id,
          Time.now.strftime("%Y-%m-%d")]).first
      @cons_current_week = Order.find_by_sql(["select count(o.id) count from orders o where o.status in (?) and o.store_id=? and
        YEARWEEK(DATE_FORMAT(o.created_at,'%Y-%m-%d'))=?", [Order::STATUS[:BEEN_PAYMENT], Order::STATUS[:FINISHED]], @store_id,
          Time.now.strftime("%Y-%m-%d")]).first
      @cons_current_month = Order.find_by_sql(["select count(o.id) count from orders o where o.status in (?) and o.store_id=? and
        DATE_FORMAT(o.created_at,'%Y-%m')=?", [Order::STATUS[:BEEN_PAYMENT], Order::STATUS[:FINISHED]], @store_id,
          Time.now.strftime("%Y-%m")]).first
    end

    amount_con_start = params[:amount_con_start]
    amount_con_end = params[:amount_con_end]
    amount_date_start = params[:amount_date_start]
    amount_date_end = params[:amount_date_end]
    c_sql = ["select c.id,c.name,c.mobilephone,c.property,csr.is_vip,
      sum(o.price) oprice,max(o.created_at) last_con_time
      from customer_store_relations csr inner join customers c on csr.customer_id=c.id
      inner join orders o on c.id=o.customer_id
      where csr.store_id=? and c.status=? and o.status in (?)
      and o.store_id=? ", @store_id, Customer::STATUS[:NOMAL], [Order::STATUS[:BEEN_PAYMENT], Order::STATUS[:FINISHED]],
      @store_id]
    unless amount_date_start.nil? || amount_date_start.strip == ""
      c_sql[0] += " and DATE_FORMAT(o.created_at,'%Y-%m-%d')>=?"
      c_sql << amount_date_start
    end
    unless amount_date_end.nil? || amount_date_end.strip == ""
      c_sql[0] += " and DATE_FORMAT(o.created_at,'%Y-%m-%d')<=?"
      c_sql << amount_date_end
    end
    c_sql[0] += " group by c.id having 1=1"
    unless amount_con_start.nil?
      c_sql[0] += " and sum(o.price)>=?"
      c_sql << amount_con_start.to_i
    end
    unless amount_con_end.nil?
      c_sql[0] += " and sum(o.price)<=?"
      c_sql << amount_con_end.to_i
    end

    @customers = Customer.paginate_by_sql(c_sql,:page => params[:page], :per_page => 10)

    respond_to do |f|
      f.html
      f.js
    end
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
        end  #扣除参加活动的产品价格
        proucts.each { |p|
          @order_prods[p.order_id].nil? ? @order_prods[p.order_id] = [p] : @order_prods[p.order_id] << p;
          @order_price[p.order_id].nil? ? @order_price[p.order_id] =(p.total_price.nil? ? 0:p.total_price)-(prices["#{p.id}-#{p.order_id}"].nil? ? 0 :prices["#{p.id}-#{p.order_id}"]) : @order_price[p.order_id]+= (p.total_price.nil? ? 0:p.total_price)-(prices["#{p.id}-#{p.order_id}"].nil? ? 0 : prices["#{p.id}-#{p.order_id}"])
        } if proucts.any?
        @total_price= complaints.inject(0){|total,prod|total += (@order_price[prod.id].nil? ? 0 : @order_price[prod.id])  }
      end
    end
    render "consumer_list"
  end

  

end
