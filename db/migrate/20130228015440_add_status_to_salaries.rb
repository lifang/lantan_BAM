class AddStatusToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :status, :boolean, :default => 0
  end
end
