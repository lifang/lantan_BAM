class AddUpdatedAtToPackageCards < ActiveRecord::Migration
  def change
    add_column :package_cards, :updated_at, :datetime
    add_index :package_cards, :updated_at
  end
end
