class CreateOrderPayTypes < ActiveRecord::Migration
  #订单付款方式
  def change
    create_table :order_pay_types do |t|
      t.integer :order_id  #订单编号
      t.integer :pay_type  #付款方式
      t.float :price
      t.datetime :created_at
    end

    add_index :order_pay_types, :order_id
    add_index :order_pay_types, :pay_type
  end
end
