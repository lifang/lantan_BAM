class AddUsernameToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :encrypted_password, :string
    add_column :customers, :username, :string
    add_column :customers, :salt, :string

    add_index :customers, :username
  end
end
