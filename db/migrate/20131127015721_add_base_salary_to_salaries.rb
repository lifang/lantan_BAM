class AddBaseSalaryToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :base_salary, :double,:default=>0
  end
end
