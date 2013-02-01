#encoding: utf-8
class Sale < ActiveRecord::Base
  has_many :sale_prod_relations
  belongs_to :store
  STATUS={:un_release=>0,:release=>1,:destroy=>2} #0 未发布 1 发布 2 删除
  DISC_TYPES = {:fee=>1,:dis=>0} #1 优惠金额  0 优惠折扣
  DISC_TIME = {:day=>1,:month=>2,:year=>3,:weekly=>4,:time=>0} #1 每日 2 每月 3 每年 4 每周 0 时间段
end
