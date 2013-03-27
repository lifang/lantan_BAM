class AddDetailsToSyncs< ActiveRecord::Migration
  def change
    add_column :syncs, :file_status, :boolean,:default=>0
    add_column :syncs, :zip_status, :boolean,:default=>0
    add_column :syncs, :sync_status, :boolean,:default=>0
  end
end
