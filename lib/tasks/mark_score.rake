#encoding: utf-8
namespace :monthly do
  desc "AS how the staff doing to mark their scores"
  task(:mark_score => :environment) do
    staff_scores = ViolationReward.vio_reward()
    Store.all.each {|store|
      Staff.where("store_id=#{store.id} and type_of_w != #{Staff::S_COMPANY[:CHIC]}").each do |staff|
        voilate = (staff_scores[ViolationReward::TYPES] && staff_scores[ViolationReward::TYPES][staff.id]) ? staff_scores[ViolationReward::TYPES][staff.id] : staff_scores[ViolationReward::TYPES][staff.id]
        reward = (staff_scores[ViolationReward::TYPES] && staff_scores[ViolationReward::TYPES][staff.id]) ? staff_scores[ViolationReward::TYPES][staff.id] : staff_scores[ViolationReward::TYPES][staff.id]
        score = voilate - reward
        month_score =MonthScore.where("staff_id=#{staff.id} and current_month=#{Time.now.months_ago(1).strftime("%Y%m").to_i}")
        if month_score.blank?
          MonthScore.create(:current_month=>Time.now.months_ago(1).strftime("%Y%m").to_i,:sys_score=>score,:staff_id=>staff.id,
            :is_syss_update=>MonthScore::IS_UPDATE[:NO], :store_id => store.id)
        else
          month_score[0].update_attributes(:sys_score=>score)
        end
      end
    }
  end
end