class CreateRevisits < ActiveRecord::Migration
#  回访表
  def change
    create_table :revisits do |t|
      t.integer :customer_id
      t.integer :types
      t.string :title  #投诉标题
      t.string :answer  #投诉回答
      t.integer :complaint_id   #投诉编号
      t.text :content  #投诉内容

      t.timestamps
    end
  end
end
