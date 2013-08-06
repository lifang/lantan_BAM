class AddShowOnPadToProducts < ActiveRecord::Migration
  def change
    add_column :products, :show_on_ipad, :boolean, :default => false
  end
end
