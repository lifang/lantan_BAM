class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.string :name
      t.datetime :started_at  
      t.datetime :ended_at
      t.text :introduction
      t.integer :disc_types   #打折方式
      t.integer :status
      t.float :discount    #折扣
      t.integer :store_id
      t.integer :disc_time_types  #打折时间方式
      t.number :car_num           #折扣数量
      t.integer :everycar_times   #每辆车的打折次数
      t.string :img_url

      t.timestamps
    end
  end
end
