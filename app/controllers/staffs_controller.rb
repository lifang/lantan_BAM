#encoding: utf-8
class StaffsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store
  before_filter :search_work_record, :only => :show

  def index
    type_of_w_sql = "type_of_w != #{Staff::S_COMPANY[:BOSS]}"
    @staffs_names = @store.staffs.not_deleted.where(type_of_w_sql).select("id, name")
    @staffs = @store.staffs.not_deleted.where(type_of_w_sql).paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    staff_scores = MonthScore.where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")} and store_id = ?", @store.id)
    @staff_scores_hash = staff_scores.group_by{|ms| ms.staff_id}
    @staff =  Staff.new
    @violation_reward = ViolationReward.new
    @train = Train.new
    @latest_updated_at = Staff.maximum("updated_at").strftime("%Y-%m-%d") unless Staff.maximum("updated_at").blank?
  end

  def search
    name_sql = params[:name].blank? ? "1=1" : ["name like ?", "%#{params[:name]}%"]
    types_sql = params[:types]=="-1" ? "1=1" : ["type_of_w = ?", "#{params[:types]}"]
    status_sql = params[:status]=="-1" ? "1=1" : ["status = ?", "#{params[:status]}"]
    type_of_w_sql = "type_of_w != #{Staff::S_COMPANY[:BOSS]}"
    @staffs = @store.staffs.not_deleted.where(type_of_w_sql).where(name_sql).where(types_sql).where(status_sql).paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    staff_scores = MonthScore.where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")} and store_id = ?", @store.id)
    @staff_scores_hash = staff_scores.group_by{|ms| ms.staff_id}
  end

  def create
    params[:staff][:username] = params[:staff][:name]
    params[:staff][:password] = params[:staff][:phone]
    params[:staff][:status] = Staff::STATUS[:normal]
    @staff = @store.staffs.new(params[:staff])
    @staff.encrypt_password
    photo = params[:staff][:photo]
    encrypt_name = random_file_name(photo.original_filename) if photo
    @staff.photo = "/uploads/#{@store.id}/#{@staff.id}/"+encrypt_name+"_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
    @staff.staff_role_relations.new(:role_id => Constant::STAFF)
    if @staff.save   #save staff info and picture
      @staff.operate_picture(photo,encrypt_name +"."+photo.original_filename.split(".").reverse[0], "create") unless photo.nil?
      flash[:notice] = "创建员工成功!"
    else
      flash[:notice] = "创建员工失败! #{@staff.errors.messages.values.flatten.join("<br/>")}"
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
    encrypt_name = random_file_name(photo.original_filename) if photo
    params[:staff][:photo] = "/uploads/#{@store.id}/#{@staff.id}/"+encrypt_name+"_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
    if  @staff && @staff.update_attributes(params[:staff])
      flash[:notice] = "更新员工成功"
    else
      flash[:notice] = "更新员工失败! #{@staff.errors.messages.values.flatten.join("<br/>")}"
    end
    #update picture
    @staff.operate_picture(photo,encrypt_name +"."+photo.original_filename.split(".").reverse[0], "update") if !photo.nil? && @staff
    redirect_to store_staff_path(@store, @staff)
  end

  def destroy
    @staff = @store.staffs.find_by_id(params[:id])
    @staff.update_attribute(:status,Staff::STATUS[:deleted] ) if @staff
    flash[:notice] = "成功删除员工"
    redirect_to store_staffs_path(@store)
  end

  def edit_info
    @staff = Staff.find_by_id(cookies[:user_id])
  end

  def update_info
    if params[:new_password] != params[:confirm_password]
      flash[:notice] = "新密码和确认密码不一致！"
      redirect_to "/stores/#{@store.id}/staffs/edit_info" and return
    end
    staff = Staff.find_by_id(cookies[:user_id])
    if staff.has_password?(params[:old_password])
        staff.password = params[:new_password]
        staff.encrypt_password
        if staff.save
          flash[:notice] = "密码修改成功！"
        else
          flash[:notice] = "密码修改失败! #{staff.errors.messages.values.flatten.join("<br/>")}"
        end
    else
      flash[:notice] = "请输入正确的旧密码！"
    end
    redirect_to "/stores/#{@store.id}/staffs/edit_info"
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

      end_at = (params[:end_at].nil? || params[:end_at].empty?) ? "1 = 1" : "date_format(current_day, '%Y-%m-%d') <= '#{params[:end_at]}'"

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
