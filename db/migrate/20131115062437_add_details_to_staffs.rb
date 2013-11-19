class AddDetailsToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :department_id, :integer
    add_column :staffs, :secure_fee, :float
    add_column :staffs, :reward_fee, :float
  end
end
