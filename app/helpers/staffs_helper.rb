#encoding: utf-8
module StaffsHelper
  
  def current_month_access_result(month_score)
    if month_score.manage_score.nil?
      access_result = "未评估"
    else
      total = month_score.manage_score.to_i + month_score.sys_score.to_i
      if total >= 90
        access_result = "优秀"
      end
      if total >= 80 && total < 90
        access_result = "良好"
      end
      if total >= 70 && total < 80
        access_result = "一般"
      end
      if total >= 60 && total < 70
        access_result = "及格"
      end
      if total < 60
        access_result = "不及格"
      end
    end
    access_result
  end

end
