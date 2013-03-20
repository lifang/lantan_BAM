#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  has_many :res_prod_relation

  STATUS = {:normal => 0, :cancel => 2, :confirmed => 1}

  def self.store_reservations store_id
    self.find_by_sql("select r.id, r.created_at,r.res_time reserv_at,r.status,c.num,cu.name,cu.mobilephone phone,cu.other_way email
     from reservations r inner join car_nums c on c.id=r.car_num_id inner join customers cu on
      cu.id=r.customer_id where r.store_id=#{store_id} and r.status != #{STATUS[:cancel]} order by r.status")
  end
end
