class CreateSaleProdRelations < ActiveRecord::Migration
  #产品销售情况
  def change
    create_table :sale_prod_relations do |t|
      t.integer :sale_id
      t.integer 
      t.integer :prod_num
:product_id
    end
    
    add_index :sale_prod_relations, :sale_id
    add_index :sale_prod_relations, :product_id
  end
end
