class CreateSaleProdRelations < ActiveRecord::Migration
  #产品销售情况
  def change
    create_table :sale_prod_relations do |t|
      t.integer :sale_id
      t.integer :product_id
      t.number :prod_num

      t.timestamps
    end
  end
end
