class CreatePcardProdRelations < ActiveRecord::Migration
  #套餐卡产品表
  def change
    create_table :pcard_prod_relations do |t|
      t.integer :product_id
      t.number :product_num
      t.integer :package_card_id

      t.timestamps
    end
  end
end
