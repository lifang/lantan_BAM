class AddPayStatusToOrderPayTypes < ActiveRecord::Migration
  def change
    add_column :order_pay_types, :pay_status, :integer,:default=>0
  end
end
