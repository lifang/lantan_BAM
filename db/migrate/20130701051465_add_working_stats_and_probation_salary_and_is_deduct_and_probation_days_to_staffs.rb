class AddWorkingStatsAndProbationSalaryAndIsDeductAndProbationDaysToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :working_stats, :int    #在职状态 0试用 1正式
    add_column :staffs, :probation_salary, :float   #试用薪资
    add_column :staffs, :is_deduct, :boolean        #是否提成
    add_column :staffs, :probation_days, :int       #试用期(天)
  end
end
