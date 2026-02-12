# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent < ApplicationAgent
  include WhatsappMessaging
  include SendMessageTool
  include SendReplyTool
  include SendMessageHistoryLinkTool

  # == Configuration ==

  helper_method :mentioned_jids_in

  # == Hooks ==

  before_action :set_instructions_context
  around_generation :send_typing_indicator_while

  # == Actions ==

  sig { void }
  def introduce_yourself
    prompt(
      tools: [SEND_MESSAGE_TOOL, SEND_MESSAGE_HISTORY_LINK_TOOL],
      tool_choice: "any",
    )
  end

  sig { void }
  def reply
    @message = message!
    prompt(
      tools: [SEND_REPLY_TOOL, SEND_MESSAGE_HISTORY_LINK_TOOL],
      tool_choice: "any",
    )
  end

  private

  # == Helpers ==

  sig { returns(WhatsappGroup) }
  def group!
    params.fetch(:group)
  end

  sig { returns(WhatsappMessage) }
  def message!
    params.fetch(:message)
  end

  sig { void }
  def set_instructions_context
    @group = group!
  end

  sig { params(block: T.proc.void).void }
  def send_typing_indicator_while(&block)
    indicator_thread = Thread.new do
      group!.send_typing_indicator
      sleep(rand(1.2..2.5))
      loop do
        group!.send_typing_indicator
        sleep(rand(0.8..2.0))
      end
    end
    yield
  ensure
    indicator_thread&.kill
  end
end
