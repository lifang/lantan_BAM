class CreateSvcardUseRecords < ActiveRecord::Migration
  #优惠卡使用表
  def change
    create_table :svcard_use_records do |t|
      t.integer :c_svc_relation_id
      t.integer :types
      t.integer :use_price
      t.integer :left_price

      t.timestamps
    end
  end
end
