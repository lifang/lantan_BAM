class CreateModels < ActiveRecord::Migration
  #功能表
  def change
    create_table :models do |t|
      t.string :name
      t.number :num

    end
  end
end
