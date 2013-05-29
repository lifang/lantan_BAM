class AddSalePriceAndUnitToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :sale_price, :float #加零售价
    add_column :materials, :unit, :string #加单位
    add_column :mat_out_orders, :types, :integer, :limit => 1 #加出库类型
  end
end
