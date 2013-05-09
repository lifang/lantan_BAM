#encoding: utf-8
namespace :monthly do
  desc "AS how the staff doing to mark their scores"
  task(:mark_score => :environment) do
    staff_scores =ViolationReward.vio_reward().inject(Hash.new){|hash,violat|hash[violat.staff_id]=violat.score;hash}
    p staff_scores
    Store.all.each {|store|
      Staff.where("store_id=#{store.id} and type_of_w != #{Staff::S_COMPANY[:CHIC]}").each do |staff|
        score = staff_scores[staff.id].nil? ? 35 : 35-staff_scores[staff.id]
        month_score =MonthScore.where("staff_id=#{staff.id} and current_month=#{Time.now.months_ago(1).strftime("%Y%m").to_i}")
        if month_score.blank?
          MonthScore.create(:current_month=>Time.now.months_ago(1).strftime("%Y%m").to_i,:sys_score=>score,:staff_id=>staff.id,
            :is_syss_update=>MonthScore::IS_UPDATE[:NO])
        else
          month_score[0].update_attributes(:sys_score=>score)
        end
      end
    }
  end
end