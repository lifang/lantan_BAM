#encoding: utf-8
class Customer < ActiveRecord::Base
  has_many :customer_num_relations
  has_many :c_svc_relations
  has_many :c_pcard_relations
  has_many :revisits, :foreign_key => "user_id"
  has_many :send_messages
  has_many :c_svc_relations
 #客户类型
  IS_VIP = {:normal=>0,:vip=>1} #0 常态客户 1 会员卡客户

  TYPES = {:good=>1,:normal=>2,:key=>3} #1优质客户 2一般客户 3 重点客户
end
