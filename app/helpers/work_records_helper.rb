#encoding: utf-8
module WorkRecordsHelper
  def get_work_record(staff)
    work_record = staff.work_records.
      where("date_format(work_records.current_day, '%Y-%m-%d')='#{Time.now.strftime("%Y-%m-%d")}'").first
    if work_record
      work_record.attendance_num > 0 ? "出勤" : "缺勤"
    else
      "缺勤"
    end
  end
end
