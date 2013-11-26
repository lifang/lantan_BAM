class AddFiveColumnToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :fact_fee, :double,:default=>0
    add_column :salaries, :work_fee, :double,:default=>0
    add_column :salaries, :manage_fee, :double,:default=>0
    add_column :salaries, :tax_fee, :double,:default=>0
    add_column :salaries, :is_edited, :boolean,:defalut=>0
  end
end
