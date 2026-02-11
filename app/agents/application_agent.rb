# typed: true
# frozen_string_literal: true

class ApplicationAgent < ActiveAgent::Base
  extend T::Sig

  include TaggedLogging
  include UrlHelpers

  # == Configuration ==

  generate_with :open_router, instructions: true
  helper AgentHelper

  # == URL Generation ==

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def default_url_options
    ActionMailer::Base.default_url_options
  end

  private

  # == Helpers ==

  sig { params(text: String).void }
  def reply_with(text)
    prompt(content_type: "text/plain") do |format|
      format.text { render plain: text }
    end
  end
end
