class AddTypesToSyncs< ActiveRecord::Migration
  def change
    add_column :syncs, :types, :integer
  end
end
