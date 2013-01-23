class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.number :deduct_num
      t.number :reward_num
      t.float :total
      t.number :current_month  #年月
      t.integer :staff_id 
      t.number :satisfied_perc  #满意程度

      t.timestamps
    end
  end
end
