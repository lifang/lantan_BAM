class CreateRoleMenuRelations < ActiveRecord::Migration
  #权限菜单表
  def change
    create_table :role_menu_relations do |t|
      t.integer :role_id
      t.integer :menu_id

      t.timestamps
    end
  end
end
