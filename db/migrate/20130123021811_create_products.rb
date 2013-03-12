class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.float :base_price
      t.float :sale_price  #销售价格
      t.text :description   #产品介绍
      t.integer :types  #清洁类，保养类。。。
      t.string :service_code   #服务代码
      t.boolean :status     #状态
      t.text :introduction
      t.boolean :is_service   #判断是产品还是服务
      t.integer :staff_level   #所需技师等级
      t.integer :staff_level_1  
      t.string :img_url
      t.integer :cost_time   #花费时长
      t.integer :store_id
      t.string :standard #规格

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :types
    add_index :products, :status
    add_index :products, :is_service
    add_index :products, :store_id
  end
end
