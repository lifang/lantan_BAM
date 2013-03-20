#encoding: utf-8
class SalaryDetail < ActiveRecord::Base
  belongs_to :staff
  belongs_to  :violation_reward

  BASE_SCORE = {:SCORE => 90} #90分为标准分，90分以下每低一份按基本工资的百分之一计算

  def self.generate_day_salary #生成每日工资单
    cal_day = (Time.now - 1.days).strftime("%Y-%m-%d")
    start_at_sql = "created_at >= '#{cal_day} 00:00:00'"
    end_at_sql = "created_at <= '#{cal_day} 23:59:59'"
    order_search_sql = "front_staff_id = ? or cons_staff_id_1 = ? or cons_staff_id_2 = ?"
    complaint_search_sql = "staff_id_1 = ? or staff_id_2 = ?"
    
    violation_rewards = ViolationReward.where(start_at_sql).where(end_at_sql).
                        group_by{|v|v.staff_id}

    violation_rewards.each do |key, value|
      value.each do |violation_reward|
        if violation_reward.types #奖励
          process_reward(violation_reward, start_at_sql, end_at_sql, order_search_sql, complaint_search_sql)
        else #处罚
          process_violation(violation_reward, start_at_sql, end_at_sql, order_search_sql, complaint_search_sql)
        end
      end  
    end
  end


  def self.process_violation(violation_reward, start_at_sql, end_at_sql, order_search_sql, complaint_search_sql)
    staff = violation_reward.staff
    
    deduct_num = 0
    if staff.is_score_ge_salary && !violation_reward.score_num.nil?
      deduct_num = staff.base_salary * (violation_reward.score_num <= 90 ? (SalaryDetail::BASE_SCORE[:SCORE] - violation_reward.score_num) : 0) * 0.01
    end
    unless violation_reward.salary_num.nil?
      deduct_num = violation_reward.salary_num
    end

    satisfied_perc = get_satisfied_perc(start_at_sql, end_at_sql, order_search_sql, complaint_search_sql, staff.id)
    SalaryDetail.create(:deduct_num => deduct_num, :staff_id => staff.id,
                        :violation_reward_id => violation_reward.id,
                        :current_day => (Time.now - 1.days).strftime("%Y%m%d").to_i,
                        :satisfied_perc => satisfied_perc, :reward_num => 0)
  end

  def self.process_reward(violation_reward, start_at_sql, end_at_sql, order_search_sql, complaint_search_sql)
    staff = violation_reward.staff
    reward_num = 0
    if staff.is_score_ge_salary && !violation_reward.score_num.nil?
      reward_num = staff.base_salary * (violation_reward.score_num >= 90 ? (violation_reward.score_num - SalaryDetail::BASE_SCORE[:SCORE]) : 0) * 0.01
    end
    unless violation_reward.salary_num.nil?
      reward_num = violation_reward.salary_num
    end

    satisfied_perc = get_satisfied_perc(start_at_sql, end_at_sql, order_search_sql, complaint_search_sql, staff.id)

    SalaryDetail.create(:reward_num => reward_num, :staff_id => staff.id,
                        :violation_reward_id => violation_reward.id,
                        :current_day => (Time.now - 1.days).strftime("%Y%m%d").to_i,
                        :satisfied_perc => satisfied_perc, :deduct_num => 0)
  end

  def self.get_satisfied_perc(start_at_sql, end_at_sql, order_search_sql, complaint_search_sql, staff_id)
    total_order = Order.where(start_at_sql).where(end_at_sql).
                        where(order_search_sql,staff_id, staff_id, staff_id).count

    total_complaint = Complaint.where(start_at_sql).where(end_at_sql).
                                where(complaint_search_sql, staff_id, staff_id).count

    satisfied_perc = total_order == 0 ? 100 : 100 - total_complaint * 100 / total_order
    satisfied_perc
  end
  
end
