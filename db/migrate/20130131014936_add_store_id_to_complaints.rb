class AddStoreIdToComplaints < ActiveRecord::Migration
  def change
    add_column :complaints, :store_id, :integer
  end
end
