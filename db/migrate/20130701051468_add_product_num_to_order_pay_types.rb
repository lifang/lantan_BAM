class AddProductNumToOrderPayTypes < ActiveRecord::Migration
  def change
    add_column :order_pay_types, :product_num, :integer  #只对套餐卡有用，记录套餐卡优惠的商品的个数
  end
end
