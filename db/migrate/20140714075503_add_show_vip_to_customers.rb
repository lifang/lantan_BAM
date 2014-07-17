class AddShowVipToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :show_vip, :boolean
  end
end
