class CreateViolationRewards < ActiveRecord::Migration
  def change
    create_table :violation_rewards do |t|
      t.integer :staff_id
      t.string :situation  #处罚/奖励原因
      t.boolean :status
      t.integer :process_types  #处置方式
      t.string :mark  #备注
      t.boolean :types   #处罚或者奖励
      t.integer :target_id  #相关订单

      t.timestamps
    end
  end
end
