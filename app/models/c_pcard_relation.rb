#encoding: utf-8
class CPcardRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :customer
  has_many :orders
  STATUS={:INVALID=>0,:NORMAL=>1} #0 为无效 1 为正常卡
  STATUS_NAME = {false=>"过期",true=>"正常使用"}
end
