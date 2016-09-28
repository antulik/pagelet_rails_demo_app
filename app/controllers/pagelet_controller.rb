class PageletController < ApplicationController
  include PageletRails::Concerns::Controller

  pagelet_options layout: 'panel'
end
