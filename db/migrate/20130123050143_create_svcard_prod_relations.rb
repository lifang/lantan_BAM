class CreateSvcardProdRelations < ActiveRecord::Migration
  #储值卡产品关系表
  def change
    create_table :svcard_prod_relations do |t|
      t.integer :product_id
      t.number :product_num
      t.integer :sv_card_id

    end
  end
end
