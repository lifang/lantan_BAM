class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :code     #订单流水号
      t.integer :car_num_id  #车牌
      t.boolean :status
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :price
      t.boolean :is_visited  #是否回访
      t.boolean :is_pleased  #是否满意
      t.boolean :is_billing  #是否要发票
      t.integer :front_staff_id  #前台
      t.integer :cons_staff_id_1  #施工甲编号
      t.string :cons_staff_id_2  #施工乙编号
      t.integer :station_id      #工位编号
      t.integer :sale_id         #参加活动
      t.integer :c_pcard_relation_id  #储值卡
      t.integer :c_svc_relation_id    #优惠卡
      t.boolean :is_free      #是否免单
      t.number :types     

      t.timestamps
    end
  end
end
