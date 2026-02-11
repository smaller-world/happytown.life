# typed: false # rubocop:disable Sorbet/TrueSigil
# frozen_string_literal: true

require "test_helper"

class WhatsappGroupAgentTest < ActiveSupport::TestCase
  extend T::Sig

  setup do
    @group = whatsapp_groups(:hangout)
    @message = whatsapp_messages(:hello_from_alice)
  end

  # == introduce_yourself ==

  test "introduce_yourself calls required tools" do
    calls = stub_tool_methods(:send_message, :send_message_history_link)

    WhatsappGroupAgent.with(group: @group)
      .introduce_yourself
      .generate_now

    assert calls[:send_message].any?,
           "Expected `send_message' to be called at least once"
    assert_equal 1,
                 calls[:send_message_history_link].length,
                 "Expected `send_message_history_link' to be called exactly once"
  end

  # == reply ==

  test "reply calls required tools" do
    calls = stub_tool_methods(:send_reply, :send_message_history_link)

    WhatsappGroupAgent.with(group: @group, message: @message)
      .reply
      .generate_now

    assert calls[:send_reply].any?,
           "Expected `send_reply' to be called at least once"
    assert calls[:send_message_history_link].length <= 1,
           "Expected `send_message_history_link' to be called at most once"
  end

  private

  sig { params(methods: Symbol).returns(T::Hash[Symbol, T::Array[T::Hash[Symbol, T.untyped]]]) }
  def stub_tool_methods(*methods)
    calls = methods.index_with { [] }

    methods.each do |method_name|
      WhatsappGroupAgent.define_method(method_name) do |**kwargs|
        calls[method_name] << kwargs
        reply_with("OK")
      end
    end

    teardown do
      methods.each { |m| WhatsappGroupAgent.remove_method(m) }
    end

    calls
  end
end
