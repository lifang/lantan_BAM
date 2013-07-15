class AddValidateCodeToStaffs < ActiveRecord::Migration
  def change
    add_column :staffs, :validate_code, :string
  end
end
