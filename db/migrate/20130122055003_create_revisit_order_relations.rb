class CreateRevisitOrderRelations < ActiveRecord::Migration
  def change
    create_table :revisit_order_relations do |t|
      t.integer :revisit_id
      t.integer :order_id

      t.timestamps
    end
  end
end
