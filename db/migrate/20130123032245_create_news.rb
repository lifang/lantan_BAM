class CreateNews < ActiveRecord::Migration
  #新闻公告表
  def change
    create_table :news do |t|
      t.string :title
      t.text :content
      t.boolean :status

      t.timestamps
    end
  end
end
