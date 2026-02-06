# typed: false
# frozen_string_literal: true

class PagesController < ApplicationController
  # == Filters ==

  allow_unauthenticated_access

  # == Actions ==

  # GET /
  def landing
    respond_to do |format|
      format.html do
        # flash.now[:notice] = "welcome to happy town!"
        render Views::Pages::Landing
      end
    end
  end
end
