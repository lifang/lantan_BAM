class CarNum < ActiveRecord::Base
  belongs_to :car_model
  has_one :customer_num_relation
  has_many :orders
  has_many :reservations

  def self.get_customer_info_by_carnum(store_id, car_num)
    sql = ["select c.id customer_id,c.name,c.mobilephone,c.other_way email,c.birthday birth,c.sex,cn.buy_year year,
      cn.id car_num_id,cn.num,cm.name model_name,cb.name brand_name
      from customer_num_relations cnr
      inner join car_nums cn on cn.id=cnr.car_num_id and cn.num= ?
      inner join customers c on c.id=cnr.customer_id and c.status=#{Customer::STATUS[:NOMAL]}
      inner join customer_store_relations csr on csr.customer_id = c.id and csr.store_id in (?)
      left join car_models cm on cm.id=cn.car_model_id
      left join car_brands cb on cb.id=cm.car_brand_id ", car_num, StoreChainsRelation.return_chain_stores(store_id)]
    customer = CustomerNumRelation.find_by_sql sql
    customer = customer[0]
    customer.birth = customer.birth.strftime("%Y-%m-%d")  if customer && customer.birth
    customer
  end
  
end
