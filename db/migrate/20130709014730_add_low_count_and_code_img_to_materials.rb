class AddLowCountAndCodeImgToMaterials < ActiveRecord::Migration
  def change
    add_column :materials, :low_count, :integer
    add_column :materials, :code_img, :string
  end
end
