#encoding: utf-8
class MonthScore < ActiveRecord::Base
  belongs_to :staff
  GOAL_NAME ={0=>"服务类",1=>"产品类",2=>"卡类",3=>"其他"}
  IS_UPDATE = {:YES=>1,:NO=>0} # 1 更新 0 未更新

  def self.sort_order(store_id)
    sql="select date_format(o.created_at,'%Y-%m-%d') day,sum(op.price) price,op.pay_type  from orders o inner join order_pay_types op
    on o.id=op.order_id where o.store_id=#{store_id} and TO_DAYS(NOW())-TO_DAYS(o.created_at)<=15 group by date_format(o.created_at,'%Y-%m-%d'),op.pay_type"
    return Order.find_by_sql(sql)
  end

  def self.sort_order_date(store_id,created,ended)
    sql ="select date_format(o.created_at,'%Y-%m-%d') day,sum(op.price) price,op.pay_type  from orders o inner join
           order_pay_types op on o.id=op.order_id where store_id=#{store_id} "
    sql += " and o.created_at>='#{created}'" unless created.nil? || created =="" || created.length==0
    sql += " and o.created_at<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql += "group by date_format(o.created_at,'%Y-%m-%d'),op.pay_type"
    return Order.find_by_sql(sql)
  end

  def self.kind_order(store_id)
    return Order.find_by_sql("select p.id,p.name,p.is_service,p.service_code,op.price,sum(op.pro_num) prod_num,sum(op.price*op.pro_num) sum,date_format(o.created_at,'%Y-%m-%d')
    day  from orders o inner join order_prod_relations op on o.id=op.order_id inner join products p on p.id=op.product_id where  o.store_id=#{store_id}
    group by p.id,date_format(o.created_at,'%Y-%m-%d') ")
  end

  def self.sort_pcard(store_id)
    return Order.find_by_sql("select p.id,p.name,p.service_code,o.is_free,op.price,sum(op.pro_num) prod_num,sum(op.price*op.pro_num) sum,date_format(o.created_at,'%Y-%m-%d')
    day  from orders o inner join order_prod_relations op on o.id=op.order_id inner join products p on p.id=op.product_id where  o.store_id=#{store_id} and (is_free=#{Order::IS_FREE[:YES]}
    or c_pcard_relation_id is not null) group by p.id,date_format(o.created_at,'%Y-%m-%d') ")
  end

  def self.search_kind_order(store_id,created,ended,time)
    sql ="select p.id,p.name,p.is_service,p.service_code,op.price,sum(op.pro_num) prod_num,sum(op.price*op.pro_num) sum,date_format(o.created_at,'%Y-%m-%d')
    day  from orders o inner join order_prod_relations op on o.id=op.order_id inner join products p on p.id=op.product_id where  o.store_id=#{store_id}"
    sql += " and o.created_at>='#{created}'" unless created.nil? || created =="" || created.length==0
    sql += " and o.created_at<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql +=" group by p.id,date_format(o.created_at,'%Y-%m-%d')"  if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql +=" group by p.id,date_format(o.created_at,'%X-%V')"  if time.to_i==Sale::DISC_TIME[:WEEK]
    sql +=" group by p.id,date_format(o.created_at,'%X-%m')"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql += " order by o.created_at desc"
    return Order.find_by_sql(sql)
  end

  def self.search_sort_pcard(store_id,created,ended,time)
    sql = "select p.id,p.name,p.service_code,o.is_free,op.price,sum(op.pro_num) prod_num,sum(op.price*op.pro_num) sum,date_format(o.created_at,'%Y-%m-%d')
    day  from orders o inner join order_prod_relations op on o.id=op.order_id inner join products p on p.id=op.product_id where  o.store_id=#{store_id} and 
    (is_free=#{Order::IS_FREE[:YES]} or c_pcard_relation_id is not null) "
    sql += " and o.created_at>='#{created}'" unless created.nil? || created == "" || created.length==0
    sql += " and o.created_at<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql +=" group by p.id,date_format(o.created_at,'%Y-%m-%d')"  if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql +=" group by p.id,date_format(o.created_at,'%X-%V')"  if time.to_i==Sale::DISC_TIME[:WEEK]
    sql +=" group by p.id,date_format(o.created_at,'%X-%m')"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql += " order by o.created_at desc"
    return Order.find_by_sql(sql)
  end

  def self.search_goals(store_id)
    return GoalSale.find_by_sql("select concat_ws('-',date_format(started_at,'%Y.%m.%d'),date_format(ended_at,'%Y.%m.%d')) day,
           type_name,goal_price,date_format(ended_at,'%Y-%m-%d') end_day,ended_at,current_price from goal_sales where store_id=#{store_id} group by id,
           concat_ws('-',date_format(started_at,'%Y.%m.%d'),date_format(ended_at,'%Y.%m.%d'))")
  end
  
end
