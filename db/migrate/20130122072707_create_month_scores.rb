class CreateMonthScores < ActiveRecord::Migration
  def change
    create_table :month_scores do |t|
      t.number :sys_score  #系统打分
      t.number :manage_score  #主管打分
      t.number :current_month  #当前月份
      t.boolean :is_syss_update #系统分数是否被更改
      t.integer :staff_id
      t.string :reason    #原因
      t.timestamps
    end
  end
end
