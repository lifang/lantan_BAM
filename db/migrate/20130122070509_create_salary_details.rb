class CreateSalaryDetails < ActiveRecord::Migration
  def change
    create_table :salary_details do |t|
      t.number :current_day  #年月日
      t.number :deduct_num   #扣款次数
      t.number :reward_num   #奖励次数
      t.float :satisfied_perc  #满意度
      t.integer :staff_id
      t.integer :voilation_reward_id 

      t.datetime :created_at
    end
  end
end
