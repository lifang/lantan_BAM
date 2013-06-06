class AddProductNumToOrderPayTypes < ActiveRecord::Migration
  def change
    add_column :order_pay_types, :product_num, :integer
  end
end
