class ChangePaymentTypeToPayReceipts < ActiveRecord::Migration
  rename_column :pay_receipts, :payment_define_id, :category_id
end