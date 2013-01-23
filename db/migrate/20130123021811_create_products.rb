class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.integer :base_price
      t.integer :sale_price  #销售价格
      t.text :description   #产品介绍
      t.integer :types
      t.string :service_code   #服务代码
      t.boolean :status
      t.text :introduction
      t.boolean :is_service
      t.integer :staff_level   #所需技师等级
      t.integer :staff_level_1  
      t.string :img_url
      t.integer :cost_time   #花费时长
      t.integer :store_id

      t.timestamps
    end
  end
end
