class CreateWorkOrders < ActiveRecord::Migration
  #工单表
  def change
    create_table :work_orders do |t|
      t.integer :station_id
      t.number :status
      t.integer :order_id
      t.datetime :started_at
      t.datetime :ended_at
      t.number :current_day
      t.number :runtime   #花费时长
      t.number :violation_num   #违规次数
      t.string :violation_reason  
      t.number :water_num
      t.number :electricity_num
      t.integer :store_id

      t.datetime :created_at
    end
  end
end
