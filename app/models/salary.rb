#encoding: utf-8
class Salary < ActiveRecord::Base
 belongs_to :staff

  def self.generate_month_salary
    #说明:员工的工资 = 奖励违规金额 + 基本工资 + 提成金额

    start_time = Time.now.months_ago(1).at_beginning_of_month
    end_time = Time.now.months_ago(1).at_end_of_month
    salary_infos = SalaryDetail.where("current_day >= #{start_time.strftime("%Y%m%d").to_i}").
                where("current_day <= '#{end_time.strftime("%Y%m%d").to_i}'").group_by{|s|s.staff_id}

    #奖励违规的金额
    staff_deduct_reward_hash = get_violation_reward_amount(salary_infos)

    #前台提成金额
    front_deduct_amount = get_front_deduct_amount

    #技师提成金额
    technician_deduct_amount = get_technician_deduct_amount

    #平均满意度
    avg_percent = get_avg_percent(start_time, end_time)

    Staff.all.each do |staff|
      deduct_amount = staff_deduct_reward_hash[staff.id].nil? ? 0 : staff_deduct_reward_hash[staff.id][:deduct_num]
      reward_amount = staff_deduct_reward_hash[staff.id].nil? ? 0 : staff_deduct_reward_hash[staff.id][:reward_num]
      percent = avg_percent[staff.id].nil? ? 100 : avg_percent[staff.id]
      if staff.type_of_w == Staff::S_COMPANY[:FRONT] #前台
        front_amount = front_deduct_amount[staff.id].nil? ? 0 : front_deduct_amount[staff.id]
        total = staff.base_salary + reward_amount - deduct_amount + front_amount*staff.deduct_percent*0.01
        Salary.create(:deduct_num => deduct_amount, :reward_num => reward_amount,
          :total => total, :current_month => start_time.strftime("%Y%m"),
          :staff_id => staff.id, :satisfied_perc => percent)
      elsif staff.type_of_w == Staff::S_COMPANY[:TECHNICIAN] #技师
        technician_amount = technician_deduct_amount[staff.id].nil? ? 0 : technician_deduct_amount[staff.id]
        total = staff.base_salary + reward_amount - deduct_amount + technician_amount*staff.deduct_percent*0.01
        Salary.create(:deduct_num => deduct_amount, :reward_num => reward_amount,
          :total => total, :current_month => start_time.strftime("%Y%m"),
          :staff_id => staff.id, :satisfied_perc => percent)
      end
    end

  end

  def self.get_violation_reward_amount(salary_infos)
    staff_deduct_reward_hash = {} #奖励违规的金额
    salary_infos.each do |staff_id, salary_details|
      staff_deduct_reward_hash[staff_id] = {:deduct_num => salary_details.sum(&:deduct_num),
                                            :reward_num => salary_details.sum(&:reward_num)}
    end
    staff_deduct_reward_hash
  end

  def self.get_front_deduct_amount
    front_deduct_amount = {}
    orders_info = Order.all.group_by{|o|o.front_staff_id}
    orders_info.each do |staff_id, orders_array|
      staff = Staff.find_by_id(staff_id)
      order_total_price = orders_array.sum(&:price)
      difference_price = order_total_price - staff.deduct_at
      duduct_num = difference_price < 0 ? 0 : (order_total_price > staff.deduct_end ? staff.deduct_end : difference_price)
      deduct_amount = duduct_num * staff.deduct_percent * 0.01
      front_deduct_amount[staff_id] = deduct_amount
    end
    front_deduct_amount
  end

  def self.get_technician_deduct_amount
    orders = Order.find_by_sql("select s2.id id_2,s.id id_1,sum(op.price*p.deduct_percent*0.01) price from orders o left join staffs s on o.cons_staff_id_1 =  s.id
       left join staffs s2 on o.cons_staff_id_2 = s2.id inner join order_prod_relations op on
        op.order_id = o.id inner join products p on op.product_id = p.id
        where p.is_service = #{Product::PROD_TYPES[:SERVICE]} group by s.id,s2.id")
    technician_deduct_amount = {}
    orders.each do |order|
      if technician_deduct_amount.keys.include?(order.id_1)
        technician_deduct_amount[order.id_1] += order.price
      else
        technician_deduct_amount[order.id_1] = order.price
      end
      if technician_deduct_amount.keys.include?(order.id_2)
        technician_deduct_amount[order.id_2] += order.price
      else
        technician_deduct_amount[order.id_2] = order.price
      end
    end
    technician_deduct_amount
  end

  def self.get_avg_percent(start_time, end_time)
    orders = Order.find_by_sql("select o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2, count(*) total_count from orders o left join staffs s on o.cons_staff_id_1 =  s.id
       left join staffs s2 on o.cons_staff_id_2 = s2.id left join staffs s3 on o.front_staff_id = s3.id where o.created_at >= '#{start_time}' and o.created_at <='#{end_time}'
       group by o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2")

    orders_info = {}
    orders.each do |order|
      if orders_info.keys.include?(order.front_staff_id)
        orders_info[order.front_staff_id] += order.total_count
      else
        orders_info[order.front_staff_id] = order.total_count
      end
      if orders_info.keys.include?(order.cons_staff_id_1)
        orders_info[order.cons_staff_id_1] += order.total_count if order.cons_staff_id_1 != order.front_staff_id
      else
        orders_info[order.cons_staff_id_1] = order.total_count
      end

      if orders_info.keys.include?(order.cons_staff_id_2)
        orders_info[order.cons_staff_id_2] += order.total_count if order.cons_staff_id_2 != order.front_staff_id && order.cons_staff_id_2 != order.cons_staff_id_1
      else
        orders_info[order.cons_staff_id_2] = order.total_count
      end
    end

    complaints = Complaint.find_by_sql("select c.staff_id_1, c.staff_id_2, count(*) total_count from complaints c left join staffs s on c.staff_id_1 = s.id
       left join staffs s2 on c.staff_id_2 = s2.id where c.process_at >= '#{start_time}' and c.process_at <='#{end_time}'
       group by c.staff_id_1, c.staff_id_2")

    complaints_info = {}
    complaints.each do |complaint|
      if complaints_info.keys.include?(complaint.staff_id_1)
        complaints_info[complaint.staff_id_1] += complaint.total_count
      else
        complaints_info[complaint.staff_id_1] = complaint.total_count
      end
      if complaints_info.keys.include?(complaint.staff_id_2)
        complaints_info[complaint.staff_id_2] += complaint.total_count if complaint.staff_id_1 != complaint.staff_id_2
      else
        complaints_info[complaint.staff_id_2] = complaint.total_count
      end
    end
    result = {}
    orders_info.each do |staff_id, order_count|
      if complaints_info[staff_id.to_i].nil?
        result[staff_id] = 100
      else
        result[staff_id] = (order_count == 0 ? 100 :complaints_info[staff_id.to_i]*100/order_count)
      end
    end
    result
  end
  
end
