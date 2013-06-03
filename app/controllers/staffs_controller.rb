#encoding: utf-8
class StaffsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store
  before_filter :search_work_record, :only => :show

  def index
    type_of_w_sql = "type_of_w != #{Staff::S_COMPANY[:BOSS]}"
    @staffs_names = @store.staffs.valid.where(type_of_w_sql).select("id, name")
    @staffs = @store.staffs.valid.where(type_of_w_sql).paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    staff_scores = MonthScore.where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")} and store_id = ?", @store.id)
    @staff_scores_hash = staff_scores.group_by{|ms| ms.staff_id}
    @staff =  Staff.new
    @violation_reward = ViolationReward.new
    @train = Train.new
    @latest_updated_at = Staff.maximum("updated_at").strftime("%Y-%m-%d") unless Staff.maximum("updated_at").blank?
  end

  def search
    sql = []
    name_sql = params[:name].blank? ? nil : "name like '%#{params[:name]}%'"
    types_sql = params[:types]=="-1" ? nil : "type_of_w = #{params[:types]}"
    status_sql = params[:status]=="-1" ? nil : "status = #{params[:status]}"
    sql<< name_sql << types_sql << status_sql
    sql = sql.compact.join(" and ")
    @staffs = @store.staffs.valid.where(sql).paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    staff_scores = MonthScore.where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")} and store_id = ?", @store.id)
    @staff_scores_hash = staff_scores.group_by{|ms| ms.staff_id}
  end

  def create
    params[:staff][:username] = params[:staff][:name]
    params[:staff][:password] = params[:staff][:phone]
    @staff = @store.staffs.new(params[:staff])
    @staff.encrypt_password
    @staff.photo = "/uploads/#{@store.id}/#{@staff.id}/"+params[:staff][:photo].original_filename.split(".")[0]+"_#{Constant::STAFF_PICSIZE.first}."+params[:staff][:photo].original_filename.split(".").reverse[0] unless params[:staff][:photo].nil?
    @staff.staff_role_relations.new(:role_id => Constant::STAFF)
    if @staff.save   #save staff info and picture
      @staff.operate_picture(params[:staff][:photo], "create") unless params[:staff][:photo].nil?
      flash[:notice] = "创建员工成功!"
    else
      flash[:notice] = "创建员工失败!"
    end
    redirect_to store_staffs_path(@store)
  end

  def show       
    @violations = @staff.violation_rewards.where("types = false").
                  paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("violation_tab")

    @rewards = @staff.violation_rewards.where("types = true").
                paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("reward_tab")
              
    @trains = Train.includes(:train_staff_relations).
              where("train_staff_relations.staff_id = #{@staff.id}").
              paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("train_tab")

    @month_scores = @staff.month_scores.order("current_month desc").paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("month_score_tab")

    @salaries = @staff.salaries.where("status = false").paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("salary_tab")

    current_month = Time.now().months_ago(1).strftime("%Y%m")

    @current_month_score = @staff.month_scores.where("current_month = #{current_month}").first

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @staff = Staff.find_by_id(params[:staff_id])
    respond_to do |format| 
      format.js
    end
  end

  def update
    @staff = Staff.find_by_id(params[:id])
    photo = params[:staff][:photo]
    params[:staff][:photo] = "/uploads/#{@store.id}/#{@staff.id}/"+photo.original_filename.split(".")[0]+"_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
    @staff.update_attributes(params[:staff]) and flash[:notice] = "更新员工成功" if @staff
    #update picture
    @staff.operate_picture(photo, "update") if !photo.nil? && @staff
    redirect_to store_staff_path(@store, @staff)
  end

  def destroy
    @staff = @store.staffs.find_by_id(params[:id])
    @staff.update_attribute(:status,Staff::STATUS[:deleted] ) if @staff
    flash[:notice] = "成功删除员工"
    redirect_to store_staffs_path(@store)
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def search_work_record
    @staff = Staff.find_by_id(params[:id])
    @tab = params[:tab]
    if @tab.nil? || @tab.eql?("work_record_tab")
      @cal_style = params[:cal_style]

      start_at = (params[:start_at].nil? || params[:start_at].empty?) ? "1 = 1" : "current_day >= '#{params[:start_at]}'"

      end_at = (params[:end_at].nil? || params[:end_at].empty?) ? "1 = 1" : "current_day <= '#{params[:end_at]} 23:59:59'"

      if @cal_style.nil? || @cal_style.empty? || @cal_style.eql?("day")
        @work_records = @staff.work_records.where(start_at).where(end_at).order("current_day desc").
                    paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
      end

      if @cal_style.eql?("week") || @cal_style.eql?("month")
        base_sql = Staff.search_work_record_sql
        @work_records = @staff.work_records.select(base_sql).
          where(start_at).where(end_at).group("#{@cal_style}(current_day)").order("current_day desc").
          paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
      end
    end

  end
  
end
