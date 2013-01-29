class AddUserNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :encrypt_password, :string
    add_column :users, :username, :string
    add_column :users, :salt, :string
  end
end
