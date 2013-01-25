class CreateMaterials < ActiveRecord::Migration
  #物料表
  def change
    create_table :materials do |t|
      t.string :name
      t.string :code  #物料编号
      t.float :price
      t.number :storage  #库存量
      t.integer :types   #是否有库存
      t.boolean :status
      t.integer :store_id  #所属门店

      t.timestamps
    end
  end
end
