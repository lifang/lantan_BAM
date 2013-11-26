class AddDetailsToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :department_id, :integer
    add_column :staffs, :secure_fee, :float,:default=>0
    add_column :staffs, :reward_fee, :float,:default=>0
  end
end
