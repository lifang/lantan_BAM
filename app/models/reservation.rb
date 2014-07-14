#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :customer
  belongs_to :car_num
  has_many :res_prod_relation, :dependent => :destroy

  STATUS = {:normal => 0, :cancel => 2, :confirmed => 1} #0  正常 1  确认预约 2 删除
  TYPES = {:PURPOSE =>0,:RESER => 1} #0 意向单 1 预约单

  def self.store_reservations store_id
    stime = " and r.created_at >= CURDATE() "
    self.find_by_sql("select r.id, r.created_at,r.res_time reserv_at,r.status,c.num,cu.name,cu.mobilephone phone,cu.other_way email
     from reservations r inner join car_nums c on c.id=r.car_num_id
      left join customer_num_relations cnr on cnr.car_num_id = c.id
      left join customers cu on cu.id=cnr.customer_id
      where r.store_id=#{store_id} and r.status != #{STATUS[:cancel]} #{stime} group by r.id order by r.status")
  end
end
