class AddIsIgnoreToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :is_ignore, :boolean, :default => 0   #是否忽略，忽略后将不受门店门店库存预警值的影响,默认不忽略
  end
end
