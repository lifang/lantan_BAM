class CreateReservations < ActiveRecord::Migration
  #预约表
  def change
    create_table :reservations do |t|
      t.integer :car_num_id
      t.number :res_time  #预约时间 年月日 小时 分钟 
      t.boolean :status   #预约状态
      t.integer :store_id

      t.timestamps
    end
  end
end
