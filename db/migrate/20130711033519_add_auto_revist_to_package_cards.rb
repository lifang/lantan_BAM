class AddAutoRevistToPackageCards < ActiveRecord::Migration
  def change
    add_column :package_cards, :is_auto_revist, :boolean
    add_column :package_cards, :auto_time, :integer
    add_column :package_cards, :revist_content, :text
    add_column :package_cards, :prod_point, :integer
  end
end
