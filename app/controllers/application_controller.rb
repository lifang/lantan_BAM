#encoding: utf-8
class ApplicationController < ActionController::Base
  include Constant
  protect_from_forgery
  include ApplicationHelper

  before_filter :set_charset
  before_filter :configure_charsets

  #中文乱码解决方案
  def set_charset
    headers["Content-Type"] = "text/html; charset=utf-8"
  end

  def configure_charsets
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    suppress(ActiveRecord::StatementInvalid) do
      ActiveRecord::Base.connection.execute 'SET NAMES UTF8'
    end
  end
end
