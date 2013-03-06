#encoding: utf-8
require 'fileutils'
class StaffsController < ApplicationController

  layout "staff"

  before_filter :get_store
  before_filter :search_work_record, :only => :show

  def index
    @staffs_names = @store.staffs.select("id, name")
    @staffs = @store.staffs.paginate(:page => params[:page] ||= 1, :per_page => 2)
    @staff =  Staff.new
    @violation_reward = ViolationReward.new
    @train = Train.new
  end

  def create
    @staff = @store.staffs.new(params[:staff])
    @staff.photo = params[:staff][:photo].original_filename
    if @staff.save
      #save picture
      FileUtils.mkdir_p "public/uploads/#{@staff.id}"
      File.new(Rails.root.join('public', "uploads", "#{@staff.id}", params[:staff][:photo].original_filename), 'a+')
      File.open(Rails.root.join('public', "uploads", "#{@staff.id}", params[:staff][:photo].original_filename), 'wb') do |file|
        file.write(params[:staff][:photo].read)
      end
    end
    redirect_to store_staffs_path(@store)
  end

  def show
    @tab = params[:tab]
           
    @violations = @staff.violation_rewards.where("types = false").
                  paginate(:page => params[:page] ||= 1, :per_page => 1)

    @rewards = @staff.violation_rewards.where("types = true").
                paginate(:page => params[:page] ||= 1, :per_page => 1)
              
    @trains = Train.includes(:train_staff_relations).
              where("train_staff_relations.staff_id = #{@staff.id}").
              paginate(:page => params[:page] ||= 1, :per_page => 1)

    @month_scores = @staff.month_scores.paginate(:page => params[:page] ||= 1, :per_page => 1)

    @salaries = @staff.salaries.where("status = false").paginate(:page => params[:page] ||= 1, :per_page => 1)

    current_month = Time.now().strftime("%Y").to_s << Time.now().strftime("%m")

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
    @staff.update_attributes(params[:staff]) if @staff
    redirect_to store_staff_path(@store, @staff)
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def search_work_record
    @cal_style = params[:cal_style]
    @staff = Staff.find_by_id(params[:id])
    start_at = (params[:start_at].nil? || params[:start_at].empty?) ? "1 = 1" : "current_day >= '#{params[:start_at]}'"

    end_at = (params[:end_at].nil? || params[:end_at].empty?) ? "1 = 1" : "current_day <= '#{params[:end_at]}'"

    if @cal_style.nil? || @cal_style.empty? || @cal_style.eql?("day")
      @work_records = @staff.work_records.where(start_at).where(end_at).
                  paginate(:page => params[:page] ||= 1, :per_page => 1)
    end

    
    if @cal_style.eql?("week") || @cal_style.eql?("month")
      base_sql = "current_day,
                SUM(attendance_num) as attendance_num_sum,
                SUM(construct_num) as construct_num_sum,
                SUM(materials_used_num) as materials_used_num_sum,
                SUM(materials_consume_num) as materials_consume_num_sum,
                SUM(water_num) as water_num_sum,
                SUM(complaint_num) as complaint_num_sum,
                SUM(train_num) as train_num_sum,
                SUM(reward_num) as reward_num_sum,
                SUM(violation_num) as violation_num_sum"


      @work_records = @staff.work_records.select(base_sql).
        where(start_at).where(end_at).group("#{@cal_style}(current_day)").
        paginate(:page => params[:page] ||= 1, :per_page => 1)
    end

  end
  
end
