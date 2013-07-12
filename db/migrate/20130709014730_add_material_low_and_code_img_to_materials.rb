class AddMaterialLowAndCodeImgToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :material_low, :integer
    add_column :materials, :code_img, :string
  end
end
