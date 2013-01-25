class CreateRevisitOrderRelations < ActiveRecord::Migration
  def change
    create_table :revisit_order_relations do |t|
      t.integer :revisit_id
      t.integer :order_id

    end
  end
end
