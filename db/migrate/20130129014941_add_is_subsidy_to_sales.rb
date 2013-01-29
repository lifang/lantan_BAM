class AddIsSubsidyToSales < ActiveRecord::Migration
  def change
    add_column :sales, :is_subsidy, :boolean
    add_column :sales, :sub_content, :string
  end
end
