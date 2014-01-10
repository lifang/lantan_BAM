#encoding: utf-8
class DataManagementsController < ApplicationController
  include MarketManagesHelper
  before_filter :sign?
  layout "complaint", :except => []
  require 'will_paginate/array'

  def index
    
  end

end
