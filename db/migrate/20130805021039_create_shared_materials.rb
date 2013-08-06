class CreateSharedMaterials < ActiveRecord::Migration
  def change
    create_table :shared_materials do |t|
      t.string :code
      t.string :name
      t.integer :types, :limit => 1
      t.string :unit

      t.timestamps
    end
  end
end
