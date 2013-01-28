class CreateWorkOrders < ActiveRecord::Migration
  #工单表
  def change
    create_table :work_orders do |t|
      t.integer :station_id
      t.integer :status
      t.integer :order_id
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :current_day
      t.integer :runtime   #花费时长
      t.integer :violation_num   #违规次数
      t.string :violation_reason  
      t.integer :water_num
      t.integer :electricity_num
      t.integer :store_id

      t.datetime :created_at
    end
  end
end
