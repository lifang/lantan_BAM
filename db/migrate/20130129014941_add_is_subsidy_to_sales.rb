class AddIsSubsidyToSales < ActiveRecord::Migration
  def change
    add_column :sales, :is_subsidy, :boolean #是否补贴
    add_column :sales, :sub_content, :string #补贴内容
  end
end
