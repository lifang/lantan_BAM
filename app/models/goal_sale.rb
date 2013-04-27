#encoding: utf-8
class GoalSale < ActiveRecord::Base
  belongs_to :store
  has_many :goal_sale_types
  TYPES_NAMES = {1 =>"产品",2 =>"服务",0 =>"卡",3 =>"其他"}
  TYPES = {:PRODUCT =>1,:SERVICE =>2,:CARD =>0,:OTHER =>3}

  #选取目前销售额当前的最大分类编号
  def self.max_type(store_id)
    return GoalSaleType.find_by_sql("select max(types) max from goal_sale_types t inner join goal_sales g on t.goal_sale_id=g.id
    where g.store_id=#{store_id} ")[0]
  end

  #查询所有的分类
  def self.total_type(store_id)
    return GoalSaleType.find_by_sql("select * from goal_sale_types t inner join goal_sales g on t.goal_sale_id=g.id
    where g.store_id=#{store_id} ")
  end

  #更新每天的销售报表
  def self.update_curr_price(store_id)
    sql ="select sum(op.price*op.pro_num) sum,p.is_service,p.types  from orders o inner join order_prod_relations op on o.id=op.order_id
     inner join products p on p.id=op.product_id where is_free is null and date_format(o.created_at,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d')
     and o.store_id=#{store_id} group by p.types"
    orders =Order.find_by_sql(sql).inject(Hash.new){|hash,order|hash[order.types].nil? ? hash[order.types]= [order] : hash[order.types] << [order];hash}
    price =orders.select {|key,value| key!=Product::TYPES_NAME[:OTHER_PROD] && key!=Product::TYPES_NAME[:OTHER_SERV] }.values.flatten.inject(Hash.new){|hash,order|
      hash[order.is_service].nil? ? hash[order.is_service]= order.sum : hash[order.is_service] += order.sum ;hash
    }
    price.merge!(GoalSale::TYPES[:OTHER]=>orders.select {|key,value|
        key==Product::TYPES_NAME[:OTHER_PROD] || key==Product::TYPES_NAME[:OTHER_SERV] }.values.flatten.inject(0){|num,order| num+=order.sum})
    car_price =CPcardRelation.find_by_sql("select sum(c.price) sum_price from c_pcard_relations c inner join package_cards p on p.id=c.package_card_id
      where p.store_id=#{store_id} and date_format(c.created_at,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d')")[0]
    price.merge!(GoalSale::TYPES[:CARD]=>car_price.sum_price.to_i)
    return price
  end


end
