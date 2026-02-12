# typed: true
# frozen_string_literal: true

require "test_helper"

class WhatsappGroupAgentTest < ActiveSupport::TestCase
  extend T::Sig

  # == Action: `introduce_yourself' ==

  test "introduce_yourself calls required tools" do
    tool_method_calls = stub_tool_methods(
      :send_message,
      :send_message_history_link,
    )

    group = whatsapp_groups(:hangout)
    WhatsappGroupAgent.with(group:)
      .introduce_yourself
      .generate_now

    assert tool_method_calls.fetch(:send_message).any?,
           "Expected `send_message' to be called at least once"
    assert_equal 1,
                 tool_method_calls.fetch(:send_message_history_link).length,
                 "Expected `send_message_history_link' to be called exactly " \
                   "once"
  end

  # == Action: `reply' ==

  test "reply calls required tools" do
    tool_method_calls = stub_tool_methods(
      :send_reply, :send_message_history_link
    )

    group = whatsapp_groups(:hangout)
    message = whatsapp_messages(:hello_message)
    WhatsappGroupAgent.with(group:, message:)
      .reply
      .generate_now

    assert tool_method_calls.fetch(:send_reply).any?,
           "Expected `send_reply' to be called at least once"
    assert_equal 0,
                 tool_method_calls.fetch(:send_message_history_link).length,
                 "Expected no calls to `send_message_history_link'"
  end

  test "reply with message history link when requested" do
    tool_method_calls = stub_tool_methods(:send_message_history_link)

    group = whatsapp_groups(:hangout)
    message = whatsapp_messages(:message_history_request_message)
    WhatsappGroupAgent.with(group:, message:)
      .reply
      .generate_now

    assert_equal 1,
                 tool_method_calls.fetch(:send_message_history_link).length,
                 "Expected `send_message_history_link' to be called exactly " \
                   "once"
  end

  private

  sig do
    params(methods: Symbol)
      .returns(T::Hash[Symbol, T::Array[T::Hash[Symbol, T.untyped]]])
  end
  def stub_tool_methods(*methods)
    original_methods = T.let({}, T::Hash[Symbol, UnboundMethod])
    calls = T.let(
      methods.index_with { [] },
      T::Hash[Symbol, T::Array[T::Hash[Symbol, T.untyped]]],
    )

    methods.each do |method_name|
      original_method = WhatsappGroupAgent.instance_method(method_name)
      original_methods[method_name] = original_method
      WhatsappGroupAgent.define_method(method_name) do |**kwargs|
        calls.fetch(method_name) << kwargs
        original_method.bind_call(self, **kwargs)
      end
    end

    teardown do
      methods.each do |method_name|
        WhatsappGroupAgent.remove_method(method_name)
      end
      original_methods.each do |method_name, original_method|
        WhatsappGroupAgent.define_method(method_name) do |**kwargs|
          original_method.bind_call(self, **kwargs)
        end
      end
    end

    calls
  end
end
