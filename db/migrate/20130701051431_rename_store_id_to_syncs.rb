class RenameStoreIdToSyncs< ActiveRecord::Migration
  def change
    remove_column :syncs,:table_name
    change_column :syncs, :zip_status,:string
    rename_column :syncs,:zip_status,:zip_name
    rename_column :syncs, :sync_id,:store_id
    rename_column :syncs, :file_status,:data_status
  end
end
