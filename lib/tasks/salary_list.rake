#encoding: utf-8
namespace :salary_list do
  desc "salary of day"
  task(:salary_of_day => :environment) do
    SalaryDetail.generate_day_salary
  end

  desc "salary of month"
  task(:month_salary => :environment) do
    Salary.generate_month_salary
  end

end