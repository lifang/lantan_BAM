class CreateNotices < ActiveRecord::Migration
  #消息提醒比偶
  def change
    create_table :notices do |t|
      t.integer :target_id   #相关订单
      t.integer :types
      t.text :content
      t.boolean :status
      t.integer :store_id

      t.timestamps
    end
  end
end
