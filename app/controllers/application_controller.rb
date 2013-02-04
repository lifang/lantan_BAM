#encoding: utf-8
class ApplicationController < ActionController::Base
  include Constant
  protect_from_forgery
  include ApplicationHelper


end
