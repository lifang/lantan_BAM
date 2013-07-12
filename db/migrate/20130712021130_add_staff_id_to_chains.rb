class AddStaffIdToChains < ActiveRecord::Migration
  def change
    add_column :chains, :staff_id, :integer
  end
end
