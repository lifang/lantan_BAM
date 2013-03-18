class AddIsScoreGenerateSalaryToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :is_score_ge_salary, :boolean, :default => false
  end
end
