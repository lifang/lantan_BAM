class AddUserNameToStaffs< ActiveRecord::Migration
  def change
    add_column :staffs, :encrypted_password, :string
    add_column :staffs, :username, :string
    add_column :staffs, :salt, :string
  end
end
