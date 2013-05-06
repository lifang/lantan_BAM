#encoding: utf-8
class WorkRecord < ActiveRecord::Base
  belongs_to :staff

  def self.update_record
    time = Time.now.strftime("%Y-%m-%d")
    work_records = WorkRecord.where("current_day >= '#{time}' and current_day <= '#{time} 23:59:59'")
    work_records.each do |work_record|
      staff = Staff.find_by_id(work_record.staff_id)
      if staff
        complaint_num = Complaint.where("process_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
                            where("process_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'").
                            where("staff_id_1 = #{work_record.staff_id} or staff_id_2 = #{work_record.staff_id}").
                            where("status = #{Complaint::STATUS[:PROCESSED]}").count

        train_num = Train.includes(:train_staff_relations).
                where("train_staff_relations.staff_id = #{work_record.staff_id}").
                where("trains.updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
                where("trains.updated_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'").count

        violation_rewards = ViolationReward.where("staff_id = #{staff.id}").
                        where("process_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
                        where("process_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'").group_by{|v|v.staff_id}
        violation_num, reward_num = 0, 0

        violation_rewards.each do |key, vio_rew_array|
          vio_rew_array.each do |vio_rew|
            if vio_rew.types#奖励
              reward_num += SalaryDetail.get_reward_amount(staff, vio_rew)
            else #违规
              violation_num += SalaryDetail.get_violation_amount(staff, vio_rew)
            end
          end
        end

        if staff.type_of_w == Staff::S_COMPANY[:TECHNICIAN]  #技师
          construct_num = Order.where("cons_staff_id_1 = #{work_record.staff_id} or cons_staff_id_2 = #{work_record.staff_id}").
                                where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}").
                                where("updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
                                where("updated_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'").count

          materials_used_num = MatOutOrder.where("staff_id = #{work_record.staff_id}").
                              where("updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
                              where("updated_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'").sum(:material_num)

          materials_consume_num = materials_used_num
          work_orders = WorkOrder.find_by_sql("select wo.id id, wo.water_num water_num, wo.electricity_num electricity_num from work_orders wo
                                             left join station_staff_relations ssr on ssr.station_id = wo.station_id
                                             where ssr.staff_id = #{work_record.staff_id} and 
                                             wo.updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}' and
                                             wo.updated_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59' and
                                             wo.status = #{WorkOrder::STAT[:COMPLETE]} and ssr.updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}' and
                                             ssr.updated_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'")
          
          water_num = work_orders.uniq{|x| x.id}.sum(&:water_num)

          elec_num = work_orders.uniq{|x| x.id}.sum(&:electricity_num)

          work_record.update_attributes(:construct_num => construct_num, :materials_used_num => materials_used_num,
                                        :materials_consume_num => materials_consume_num, :water_num => water_num,
                                        :electricity_num => elec_num, :complaint_num => complaint_num, :train_num => train_num,
                                        :violation_num => violation_num, :reward_num => reward_num)
        else
          if staff.type_of_w == Staff::S_COMPANY[:FRONT]  #前台
            construct_num = Order.where("front_staff_id = #{work_record.staff_id}").
                                where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}").
                                where("updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
                                where("updated_at <= '#{work_record.current_day.strftime("%Y-%m-%d")} 23:59:59'").count
            work_record.update_attributes(:construct_num => construct_num, :complaint_num => complaint_num,
                                          :train_num => train_num, :violation_num => violation_num, :reward_num => reward_num)
          else #店长
            work_record.update_attributes(:complaint_num => complaint_num, :train_num => train_num,
                                        :violation_num => violation_num, :reward_num => reward_num)
          end
        end
      end

    end
  end
end
