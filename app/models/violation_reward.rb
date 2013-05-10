#encoding: utf-8
class ViolationReward < ActiveRecord::Base
  belongs_to :staff
  has_many :salary_details
  
  VIOLATE = {:deducate =>1,:cut=>2,:decrease=>3,:fire=>4,:invalid => 5} #1 扣考核分 2 按分值扣款 3 严重的降级 4 辞退 5 无效
  N_VIOLATE = {1 => "扣考核分", 2 => "按分值扣款", 3 => "严重的降级", 4 => "辞退", 5 => "无效"}

  REWARD = {:reward=>1,:salary=>2,:reduce=>3,:vocation=>4,:invalid => 5} #1 奖金 2 加薪 3 缩短升值期限 4 带薪假期 5 无效
  N_REWARD = {1 => "奖金", 2 => "加薪", 3 => "缩短升值期限", 4 => "带薪假期", 5 => "无效"}

  TYPES = {:VIOLATION => 0, :REWARD => 1} #0 处罚  1 奖励

  STATUS = {:NOMAL => 0, :PROCESSED => 1} #0 未处理  1 已处理

  def self.vio_reward()
    sql = "select sum(score_num) score,staff_id from violation_rewards v inner join staffs s on v.staff_id=s.id where v.types=?
    and v.process_types=? and date_format(v.process_at,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m') group by staff_id"
    return ViolationReward.find_by_sql([sql,ViolationReward::TYPES[:VIOLATION],ViolationReward::VIOLATE[:deducate]])
  end

end
