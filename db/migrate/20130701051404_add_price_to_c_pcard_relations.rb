class AddPriceToCPcardRelations < ActiveRecord::Migration
  def change
    add_column :c_pcard_relations, :price, :integer,:default=>0
  end
end
