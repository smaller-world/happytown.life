# typed: true
# frozen_string_literal: true

require "test_helper"

class WhatsappGroupAgentTest < ActiveSupport::TestCase
  extend T::Sig

  setup do
    @group = whatsapp_groups(:hangout)
    @message = whatsapp_messages(:hello_from_alice)
    @sender = whatsapp_users(:alice)
  end

  # == introduce_yourself ==

  test "introduce_yourself configures send_message and send_message_history_link tools" do
    generation = WhatsappGroupAgent.with(group: @group).introduce_yourself

    prompt_options = generation.prompt_options
    tool_names = prompt_options[:tools].map { |tool| tool[:name] }

    assert_includes tool_names, "send_message"
    assert_includes tool_names, "send_message_history_link"
    assert_equal 2, tool_names.length
  end

  test "introduce_yourself requires tool use" do
    generation = WhatsappGroupAgent.with(group: @group).introduce_yourself

    prompt_options = generation.prompt_options

    assert_equal "required", prompt_options[:tool_choice]
  end

  test "introduce_yourself includes group context in instructions" do
    generation = WhatsappGroupAgent.with(group: @group).introduce_yourself

    instructions = generation.instructions

    assert_includes instructions, @group.subject
  end

  # == reply ==

  test "reply configures send_reply and send_message_history_link tools" do
    generation = WhatsappGroupAgent.with(group: @group, message: @message).reply

    prompt_options = generation.prompt_options
    tool_names = prompt_options[:tools].map { |tool| tool[:name] }

    assert_includes tool_names, "send_reply"
    assert_includes tool_names, "send_message_history_link"
    assert_equal 2, tool_names.length
  end

  test "reply requires tool use" do
    generation = WhatsappGroupAgent.with(group: @group, message: @message).reply

    prompt_options = generation.prompt_options

    assert_equal "required", prompt_options[:tool_choice]
  end

  test "reply includes incoming message in prompt" do
    generation = WhatsappGroupAgent.with(group: @group, message: @message).reply

    preview = generation.preview_prompt

    assert_includes preview, @message.body
  end

  # == send_message tool ==

  test "send_message sends message to the group" do
    stub_group_messaging do
      agent = build_agent(group: @group)
      agent.send_message(text: "hello world")
    end

    assert_equal 1, sent_messages.length
    first_message = T.must(sent_messages.first)
    assert_equal "hello world", first_message[:text]
  end

  # == send_reply tool ==

  test "send_reply calls send_message" do
    stub_group_messaging do
      agent = build_agent(group: @group, message: @message)
      agent.send_reply(text: "here to help!")
    end

    assert_equal 1, sent_messages.length
    first_message = T.must(sent_messages.first)
    assert_includes first_message[:text], "here to help!"
  end

  test "send_reply prepends sender mention when not already mentioned" do
    stub_group_messaging do
      agent = build_agent(group: @group, message: @message)
      agent.send_reply(text: "here to help!")
    end

    first_message = T.must(sent_messages.first)
    assert_includes first_message[:text], @sender.embedded_mention
  end

  # == send_message_history_link tool ==

  test "send_message_history_link sends message with group history URL" do
    stub_group_messaging do
      agent = build_agent(group: @group)
      agent.send_message_history_link
    end

    assert_equal 1, sent_messages.length
    first_message = T.must(sent_messages.first)
    assert_includes first_message[:text], "/groups/"
    assert_includes first_message[:text], "/message_history"
  end

  private

  sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def sent_messages
    T.must(@sent_messages)
  end

  sig { params(group: WhatsappGroup, message: T.nilable(WhatsappMessage)).returns(WhatsappGroupAgent) }
  def build_agent(group:, message: nil)
    agent = WhatsappGroupAgent.new
    agent.params = { group:, message: }.compact
    agent.instance_variable_set(:@message, message) if message
    agent
  end

  sig { params(block: T.proc.void).void }
  def stub_group_messaging(&block)
    @sent_messages = T.let(
      [],
      T.nilable(T::Array[T::Hash[Symbol, T.untyped]]),
    )
    WhatsappGroup.define_method(:send_message) do |text:, mentioned_jids: nil|
      test_sent_messages = Thread.current[:test_sent_messages]
      test_sent_messages << { text:, mentioned_jids: } if test_sent_messages
    end

    Thread.current[:test_sent_messages] = @sent_messages
    yield
  ensure
    Thread.current[:test_sent_messages] = nil
    WhatsappGroup.remove_method(:send_message)
  end
end
