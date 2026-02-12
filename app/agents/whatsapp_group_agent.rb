# typed: true
# frozen_string_literal: true

class WhatsappGroupAgent < ApplicationAgent
  include WhatsappMessaging
  include SendMessageTool
  include SendReplyTool
  include SendMessageHistoryLinkTool

  # == Configuration ==

  generate_with :open_router, instructions: true, temperature: 0
  helper_method :mentioned_jids_in

  # == Hooks ==

  before_action :set_instructions_context
  around_generation :send_typing_indicator_while
  around_generation :log_completion_after

  # == Actions ==

  sig { void }
  def introduce_yourself
    prompt(
      tools: [SEND_MESSAGE_TOOL, SEND_MESSAGE_HISTORY_LINK_TOOL],
      tool_choice: "required",
      # response_format: :json_object,
    )
  end

  sig { void }
  def reply
    @message = message!
    prompt(
      tools: [SEND_REPLY_TOOL, SEND_MESSAGE_HISTORY_LINK_TOOL],
      tool_choice: "required",
      # response_format: :json_object,
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

  # == Callbacks ==

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

  sig do
    params(block: T.proc.returns(
      ActiveAgent::Providers::Common::Responses::Prompt,
    )).void
  end
  def log_completion_after(&block)
    response = yield
    output = response.message.content
    tag_logger do
      logger.info("Generation completed: #{format_output_for_logging(output)}")
      if Rails.env.test?
        logger.debug("Full thread: #{response.messages}")
      end
      warn_on_bad_output(output)
    end
    response
  end

  sig { params(output: String).returns(String) }
  def format_output_for_logging(output)
    if output.blank?
      return "(empty output)"
    end

    JSON.parse(output).to_s
  rescue JSON::ParserError
    output
  end

  sig { params(output: String).void }
  def warn_on_bad_output(output)
    if output.blank?
      tag_logger do
        logger.warn("Got empty output")
      end
    end

    result = JSON.parse(output)
    if result.is_a?(Hash)
      if result["tools_used"].blank?
        tag_logger do
          logger.warn("No tool usage reported: #{result}")
        end
      end
    else
      tag_logger do
        logger.warn("Unexpected JSON output: #{output}")
      end
    end
  rescue JSON::ParserError
    tag_logger do
      logger.warn("Invalid JSON output: #{output}")
    end
  end
end
