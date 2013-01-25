class CreateRoleModelRelations < ActiveRecord::Migration
  #权限功能表
  def change
    create_table :role_model_relations do |t|
      t.integer :role_id
      t.number :num

    end
  end
end
