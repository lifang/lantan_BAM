#encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_prod_relations
  has_many :order_pay_types
  has_many :work_orders
  has_many :revisits
  belongs_to :car_num
  belongs_to :c_pcard_relation
  belongs_to :c_svc_relation
  has_many :revisit_order_relations

  IS_VISITED = {:YES => 1, :NO => 0} #1 已访问  0 未访问
  STATUS = {:NORMAL => 0, :SERVICING => 1, :WAIT_PAYMENT => 2, :BEEN_PAYMENT => 3, :FINISHED => 4, :DELETED => 5}
  #0 正常未进行  1 服务中  2 等待付款  3 已经付款  4 已结束  5已删除

  TYPES = {:SERVICE => 0, :PRODUCT => 1} #0 服务  1 产品

  #是否满意
  IS_PLEASED = {:BAD => 0, :SOSO => 1, :GOOD => 2, :VERY_GOOD => 3}  #0 不满意  1 一般  2 好  3 很好
  IS_PLEASED_NAME = {0 => "不满意", 1 => "一般", 2 => "好", 3 => "很好"}

  #组装查询order的sql语句
  def self.generate_order_sql(started_at, ended_at, is_visited)
    condition_sql = ""
    params_arr = [""]
    unless started_at.nil? or started_at.strip.empty?
      condition_sql += " and o.created_at >= ? "
      params_arr << started_at.strip
    end
    unless ended_at.nil? or ended_at.strip.empty?
      condition_sql += " and o.created_at <= ? "
      params_arr << ended_at.strip
    end
    unless is_visited.nil? or is_visited == "-1"
      condition_sql += " and o.is_visited = ? "
      params_arr << is_visited.to_i
    end
    return [condition_sql, params_arr]
  end

  #获取需要回访的订单
  def self.get_revisit_orders(store_id, started_at, ended_at, is_visited, is_time, time, is_price, price)
    base_sql = "select o.customer_id from orders o
      where o.store_id = #{store_id.to_i} and o.status != #{STATUS[:DELETED]} "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    group_by_sql = ""

    if !is_time.nil? and !time.nil? and !time.strip.empty?
      group_by_sql += " group by o.customer_id having count(o.id) >= ? "
      params_arr << time.to_i
    end
    if !is_price.nil? and !price.nil? and !price.strip.empty?
      group_by_sql == "" ? group_by_sql = " group by o.customer_id having sum(o.price) >= ? "
      : group_by_sql += " or sum(o.price) >= ? "
      params_arr << price.to_i
    end
    params_arr[0] = base_sql + condition_sql + group_by_sql
    return Order.find_by_sql(params_arr).collect{ |i| i.customer_id }
  end

  #组装查询customer的sql
  def self.generate_customer_sql(condition_sql, params_arr, store_id, started_at, ended_at, is_visited,
      is_vip, is_time, time, is_price, price, is_birthday)
    customer_condition_sql = condition_sql
    customer_params_arr = params_arr.collect { |p| p }
    unless is_vip.nil? or is_vip == "-1"
      customer_condition_sql += " and cu.is_vip = ? "
      customer_params_arr << is_vip.to_i
    end
    unless is_birthday.nil?
      customer_condition_sql += " and datediff(now(), cu.birthday)%365 >= 355 "
    end
    customer_ids = self.get_revisit_orders(store_id, started_at, ended_at, is_visited, is_time, time, is_price, price)
    unless customer_ids.nil? or customer_ids.blank?
      customer_condition_sql += " and cu.id in (?) "
      customer_params_arr << customer_ids
    end
    return [customer_params_arr, customer_condition_sql, customer_ids]
  end

  #根据需要回访的订单列出客户
  def self.get_order_customers(store_id, started_at, ended_at, is_visited, is_time, time, is_price, 
      price, is_vip, is_birthday, page)
    customer_sql = "select cu.id cu_id, cu.name, cu.mobilephone, cn.num, o.code, o.id o_id from customers cu
      inner join orders o on o.customer_id = cu.id left join car_nums cn on cn.id = o.car_num_id
      where cu.status = #{STATUS[:NOMAL]} and o.store_id = #{store_id.to_i} and o.status != #{STATUS[:DELETED]} "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    customer_condition_sql = self.generate_customer_sql(condition_sql, params_arr, store_id, started_at,
      ended_at, is_visited, is_vip, is_time, time, is_price, price, is_birthday)
    customer_condition_sql[0][0] = customer_sql + customer_condition_sql[1]
    return customer_condition_sql[2].blank? ? [] :
      Customer.paginate_by_sql(customer_condition_sql[0], :per_page => 1, :page => page)
  end

  #查询需要发短信的用户
  def self.get_message_customers(store_id, started_at, ended_at, is_visited, is_time, time, is_price,
      price, is_vip, is_birthday)
    customer_sql = "select cu.id cu_id, cu.name from customers cu where cu.status = #{STATUS[:NOMAL]} "
    customer_condition_sql = self.generate_customer_sql("", [""], store_id, started_at, ended_at, is_visited,
      is_vip, is_time, time, is_price, price, is_birthday)
    condition_arr = customer_condition_sql[0]
    condition_sql = customer_condition_sql[1]
    condition_arr[0] = customer_sql + condition_sql
    return customer_condition_sql[2].blank? ? [] : Customer.find_by_sql(condition_arr)
    
  end

  def self.one_customer_orders(status, store_id, customer_id, pre_page, page)
    @orders = Order.paginate_by_sql(["select * from orders where status != ? and store_id = ? and customer_id = ?
        order by created_at desc", status, store_id, customer_id], :per_page => pre_page, :page => page)
  end

  #施工中的订单
  def self.working_orders status,store_id
    Order.find_by_sql("select o.id,c.num from orders o inner join car_nums c on c.id=o.car_num_id where o.status=#{status}
      and o.store_id=#{store_id} order by o.created_at")
  end

  def self.search_by_car_num store_id,car_num
    customer = nil
    working_orders = []
    old_orders = []
    sql = "select c.id customer_id,c.name,c.mobilephone,cn.id car_num_id,cn.num,cm.name model_name,cb.name brand_name
      from customer_num_relations cnr
      inner join car_nums cn on cn.id=cnr.car_num_id and cn.num='#{car_num}'
      inner join customers c on c.id=cnr.customer_id and c.status=#{Customer::STATUS[:NOMAL]}
      inner join car_models cm on cm.id=cn.car_model_id
      inner join car_brands cb on cb.id=cm.car_brand_id "
    customer = CustomerNumRelation.find_by_sql sql
    if customer && customer.size > 0
      customer = customer[0]
      orders = Order.find_by_sql("select * from orders o where o.car_num_id=#{customer.car_num_id}
        and o.status!=#{STATUS[:DELETED]} and o.store_id=#{store_id} order by o.created_at desc")
      (orders || []).each do |order|
         order_hash = order
         #puts order_hash
         order_hash[:products] = order.order_prod_relations.collect{|r|
           p = Hash.new
           p[:name] = r.product.name
           p[:price] = r.price.to_f * r.pro_num.to_i
           p
         }
         order_hash[:pay_type] = order.order_pay_types.collect{|type|
            OrderProdRelation::PAY_TYPES_NAME[type.pay_type]
         }.join(",")
         if order.sale_id
           s = Hash.new
           s[:name] = "huodong"
           s[:price] = 12
           s[:num] = 22
           order_hash[:products] << s
         end
         if order.c_pcard_relation_id

         end
         if order.c_svc_relation_id

         end
         front_staff = Staff.find_by_id_and_store_id order.front_staff_id,store_id
         order_hash[:staff] = front_staff.name if front_staff
         if order.status == STATUS[:FINISHED]
            old_orders << order_hash
         else
            working_orders << order_hash
         end
      end
      working_orders = working_orders.first if working_orders.size > 0
      #puts old_orders.to_json,working_orders.to_json,customer.to_json
    else

    end
    [customer,working_orders,old_orders]
  end

  def self.get_brands_products store_id
    arr = []
    brands = CarBrand.all :order => "id"
    brand_arr = []
    (brands || []).each do |brand|
      b = brand
      b[:models] = brand.car_models
      brand_arr << b
    end
    arr << brand_arr
    product_arr = []
    clean_arr = []
    prod_arr = []
    maint_arr = []
    card_arr = []
    products = Product.find_all_by_store_id_and_status store_id Product::IS_VALIDATE[:YES]
    (products || []).each do |p|
       if p.types.to_i <=4
         prod_arr << p
       elsif p.types.to_i == 5
          clean_arr << p
       elsif p.types.to_i > 5
          maint_arr << p
       end
    end
    product_arr << clean_arr
    product_arr << maint_arr
    product_arr << prod_arr
    cards = PackageCard.find_all_by_store_id_and_status store_id PackageCard::STAT[:NORMAL]
    product_arr << cards
    arr << product_arr
    arr
  end

  def self.one_order_info(order_id)
    return Order.find_by_sql(["select o.id, o.code, o.created_at, o.sale_id, o.price, o.c_pcard_relation_id, o.store_id,
      o.is_free, o.c_svc_relation_id, c.name front_s_name, c1.name cons_s_name1,
      c2.name cons_s_name2, o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2
      from orders o left join customers c on c.id = o.front_staff_id left join customers c1 on c1.id = o.cons_staff_id_1
      left join customers c2 on c2.id = o.cons_staff_id_2 where o.id = ?", order_id])
  end

end
