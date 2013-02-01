#encoding: utf-8
class Sale < ActiveRecord::Base
  has_many :sale_prod_relations
  belongs_to :store
  STATUS={:UN_RELEASE =>0,:RELEASE =>1,:DESTROY =>2} #0 未发布 1 发布 2 删除
  DISC_TYPES = {:FEE=>1,:DIS=>0} #1 优惠金额  0 优惠折扣
  DISC_TIME = {:DAY=>1,:MOUTH=>2,:YEAR=>3,:WEEK=>4,:TIME=>0} #1 每日 2 每月 3 每年 4 每周 0 时间段
end
