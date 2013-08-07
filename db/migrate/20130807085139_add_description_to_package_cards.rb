class AddDescriptionToPackageCards < ActiveRecord::Migration
  def change
    add_column :package_cards, :description, :string
  end
end
