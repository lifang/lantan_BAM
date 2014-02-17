class AddAutoWarnToPackageCards< ActiveRecord::Migration
  def change
    add_column :package_cards, :auto_warn, :boolean,:default=>0
    add_column :package_cards, :time_warn, :integer
    add_column :package_cards, :con_warn, :string
  end
end
