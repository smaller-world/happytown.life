# typed: true
# frozen_string_literal: true

class ApplicationAgent < ActiveAgent::Base
  extend T::Sig

  # == Configuration ==

  generate_with :open_router, instructions: true
  helper AgentHelper
end
