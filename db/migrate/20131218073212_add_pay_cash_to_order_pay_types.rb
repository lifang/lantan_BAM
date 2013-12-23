class AddPayCashToOrderPayTypes < ActiveRecord::Migration
  def change
    add_column :order_pay_types, :pay_cash, :integer,:default=>0
    add_column :order_pay_types, :second_parm, :string,:default=>0
  end
end
