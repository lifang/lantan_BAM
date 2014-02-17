class AddCreateProdToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :create_prod, :boolean,:defalut=>0
  end
end
