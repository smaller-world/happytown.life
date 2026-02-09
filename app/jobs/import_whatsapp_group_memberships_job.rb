# typed: true
# frozen_string_literal: true

class ImportWhatsappGroupMembershipsJob < ApplicationJob
  # == Configuration ==

  queue_as :default

  # == Job ==

  sig { params(group: WhatsappGroup).void }
  def perform(group)
    group.import_memberships
  end
end
