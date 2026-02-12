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
      :send_reply,
      :send_message_history_link,
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
    tool_method_calls = stub_tool_methods(
      :send_reply,
      :send_message_history_link,
    )

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
    calls = T.let(
      methods.index_with { [] },
      T::Hash[Symbol, T::Array[T::Hash[Symbol, T.untyped]]],
    )

    WhatsappGroupAgent.class_eval do
      methods.each do |method_name|
        original_method_name = :"original_#{method_name}"
        alias_method original_method_name, method_name

        define_method(method_name) do |**kwargs|
          calls.fetch(method_name) << kwargs
          "OK"
        end
      end
    end

    teardown do
      WhatsappGroupAgent.class_eval do
        methods.each do |method_name|
          original_method_name = :"original_#{method_name}"
          alias_method method_name, original_method_name
          remove_method original_method_name
        end
      end
    end

    calls
  end
end
