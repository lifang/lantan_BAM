class AddDetailsToRoles< ActiveRecord::Migration
  def change
    add_column :syncs, :file_status, :boolean
    add_column :syncs, :zip_status, :boolean
    add_column :syncs, :sync_status, :boolean
  end
end
