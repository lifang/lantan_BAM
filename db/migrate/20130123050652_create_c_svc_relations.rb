class CreateCSvcRelations < ActiveRecord::Migration
  #客户储值卡关系表
  def change
    create_table :c_svc_relations do |t|
      t.integer :customer_id
      t.integer :sv_card_id
      t.float :total_price
      t.float :left_price
      t.string :id_card  #客户身份证

      t.datetime :created_at
    end

    add_index :c_svc_relations, :customer_id
    add_index :c_svc_relations, :sv_card_id
  end
end
