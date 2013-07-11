class AddTotalPointToCustomer < ActiveRecord::Migration
  def change
    add_column :customers,:total_point,:integer
  end
end
