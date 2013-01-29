#encoding: utf-8
class ViolationReward < ActiveRecord::Base
  belongs_to :staff
  has_many :salary_details
  
  VIOLATE = {:deducate=>1,:cut=>2,:decrease=>3,:fire=>4} #1 扣考核分 2 按分值扣款 3 严重的降级 4 辞退
  REWARD = {:reward=>1,:salary=>2,:reduce=>3,:vocation=>4} #1 奖金 2 加薪 3 缩短升值期限 4 带薪假期
end
