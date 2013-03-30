class AddTypesToSyncs< ActiveRecord::Migration
  def change
    add_column :syncs, :types, :integer
    add_column :syncs, :has_data, :boolean,:default=>1
  end
end
