class AddLimitedPasswordToStores < ActiveRecord::Migration
  def change
    add_column :stores, :limited_password, :string
  end
end
