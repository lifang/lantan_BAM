class ChangePaymentTypeToPayReceipts < ActiveRecord::Migration
  rename_column :pay_receipts, :payment_type, :payment_define_id
end