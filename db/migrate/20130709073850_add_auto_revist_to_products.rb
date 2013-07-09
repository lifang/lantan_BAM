class AddAutoRevistToProducts < ActiveRecord::Migration
  def change
    add_column :products, :is_auto_revist, :boolean
    add_column :products, :auto_time, :integer
    add_column :products, :revist_content, :text
  end
end
