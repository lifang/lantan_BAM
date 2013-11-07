class AddSingleTypesToProducts < ActiveRecord::Migration
  def change
    add_column :products, :single_types, :integer,:defalut=>0
  end
end
