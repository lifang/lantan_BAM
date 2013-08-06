class AddShowOnPadToProducts < ActiveRecord::Migration
  def change
    add_column :products, :show_on_ipad, :boolean, :default => true #判断服务是否在ipad端显示
  end
end
