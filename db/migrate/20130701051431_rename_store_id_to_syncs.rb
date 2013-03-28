class RenameStoreIdToSyncs< ActiveRecord::Migration
  def change
    change_column :syncs, :zip_status,:string
    rename_column :syncs,:zip_status,:zip_name
    rename_column :syncs, :file_status,:data_status
  end
end
