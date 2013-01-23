class CreateMenus < ActiveRecord::Migration
  #菜单表
  def change
    create_table :menus do |t|
      t.string :controller

      t.timestamps
    end
  end
end
