class AddImportPriceToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :import_price, :"decimal(20,2)"
  end
end
