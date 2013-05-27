class AddMaterialLowToStores < ActiveRecord::Migration
  def change
    add_column :stores, :material_low, :integer   #设置该门店的库存数量预警值，当低于该值时，显示缺货警告
  end
end
