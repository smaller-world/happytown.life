# typed: true
# frozen_string_literal: true

class HomesController < ApplicationController
  # == Actions ==

  # GET /home
  def show
    respond_to do |format|
      format.html do
        render Views::Homes::Show
      end
    end
  end
end
