#encoding: utf-8
require 'fileutils'
class StaffsController < ApplicationController

  layout "staff"

  before_filter :get_store

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

      flash[:notice] = "创建员工成功！"
    else
      flash[:notice] = "创建员工失败！"
    end
    redirect_to store_staffs_path(@store)
  end

  def show
    @tab = params[:tab]
    @staff = Staff.find_by_id(params[:id])
    @work_records = @staff.work_records.paginate(:page => params[:page] ||= 1, :per_page => 1)
    @violations = @staff.violation_rewards.where("types = false").
                  paginate(:page => params[:page] ||= 1, :per_page => 1)

    @rewards = @staff.violation_rewards.where("types = true").
                paginate(:page => params[:page] ||= 1, :per_page => 1)
              
    @trains = Train.includes(:train_staff_relations).
              where("train_staff_relations.staff_id = #{@staff.id}").
              paginate(:page => params[:page] ||= 1, :per_page => 1)

    @month_scores = @staff.month_scores.paginate(:page => params[:page] ||= 1, :per_page => 1)

    @salaries = @staff.salaries.paginate(:page => params[:page] ||= 1, :per_page => 1)

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
    redirect_to store_staffs_path(@store)
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
