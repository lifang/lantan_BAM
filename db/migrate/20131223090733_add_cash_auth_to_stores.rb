class AddCashAuthToStores < ActiveRecord::Migration
  def change
    add_column :stores, :cash_auth, :integer, :default => 0 #该门店是否有在pad上收银的权限
  end
end
