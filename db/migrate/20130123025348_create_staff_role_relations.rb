class CreateStaffRoleRelations < ActiveRecord::Migration
  #员工权限表
  def change
    create_table :staff_role_relations do |t|
      t.integer :role_id
      t.integer :staff_id

      t.timestamps
    end
  end
end
