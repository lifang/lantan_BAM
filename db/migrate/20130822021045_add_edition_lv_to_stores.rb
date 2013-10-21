class AddEditionLvToStores < ActiveRecord::Migration
  def change
    add_column :stores, :edition_lv, :integer     #门店使用的系统的版本等级
    add_index :stores, :edition_lv
  end
end
