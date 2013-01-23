class CreateCPcardRelations < ActiveRecord::Migration
  #客户套餐卡表
  def change
    create_table :c_pcard_relations do |t|
      t.integer :customer_id
      t.integer :package_card_id
      t.datetime :ended_at
      t.boolean :status
      t.text :content

      t.timestamps
    end
  end
end
