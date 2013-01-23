class CreateComplaints < ActiveRecord::Migration
  def change
    create_table :complaints do |t|
      t.integer :order_id
      t.text :reason
      t.text :suggstion
      t.text :remark
      t.boolean :status
      t.integer :types
      t.integer :staff_id_1  #投诉技师
      t.integer :staff_id_2
      t.number :process_at   #处理时间
      t.boolean :is_violation   #是否违规
      t.integer :customer_id

      t.timestamps
    end
  end
end
