class AddAutoSendToStores < ActiveRecord::Migration
  def change
    add_column :stores, :auto_send, :integer,:default=>1
  end
end
