class CreateWOTimes < ActiveRecord::Migration
  #工位排单
  def change
    create_table :w_o_times do |t|
      t.integer :current_time  #当天时间  小时分钟
      t.integer :current_day   #年月日
      t.integer :station_id   #工单编号
      t.integer :worked_num   #已工作次数
      t.integer :wait_num     #目前等待数量

      t.datetime :created_at
    end
  end
end
