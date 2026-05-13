# typed: strict
# frozen_string_literal: true

module Wsapi
  class Client
    extend T::Sig
    include TaggedLogging

    # == Configuration ==

    sig { params(api_key: String, instance_id: String).void }
    def initialize(api_key:, instance_id:)
      @session = T.let(
        HTTP
          .use(logging: { logger: tagged_logger })
          .base_uri("https://api.wsapi.chat")
          .headers(
            "X-Api-Key" => api_key,
            "X-Instance-Id" => instance_id,
          ),
        HTTP::Session,
      )
    end

    # == Methods ==

    sig { params(to: String, text: String).void }
    def send_message(to:, text:)
      unless perform_deliveries?
        tag_logger do
          logger.info("Skipping message delivery to #{to}: #{text}")
        end
        return
      end

      payload = { to:, text: }.compact_blank
      tag_logger do
        logger.info("Sending message: #{payload}")
      end
      post!("/messages/text", json: payload)
    end

    sig { params(community_id: String, participant_ids: T::Array[String]).void }
    def remove_community_participants(community_id:, participant_ids:)
      unless perform_deliveries?
        tag_logger do
          logger.info(
            "Skipping removing participants from community " \
              "#{community_id}: #{participant_ids}",
          )
        end
        return
      end

      groups = get!("/communities/#{community_id}/groups")
      announcement_group = groups.find { |group| group["isAnnouncementGroup"] }
      unless announcement_group
        raise Error, "Failed to find announcement group for community #{community_id}"
      end

      announcement_group_id = announcement_group.fetch("groupId")

      payload = { participants: participant_ids, action: "remove" }
      tag_logger do
        logger.info("Removing participants from community #{community_id}: #{payload}")
      end
      put!("/groups/#{announcement_group_id}/participants", json: payload)
    end

    sig { params(group_id: String, participant_ids: T::Array[String]).void }
    def remove_group_participants(group_id:, participant_ids:)
      unless perform_deliveries?
        tag_logger do
          logger.info(
            "Skipping removing participants from group " \
              "#{group_id}: #{participant_ids}",
          )
        end
        return
      end

      payload = { participants: participant_ids, action: "remove" }
      tag_logger do
        logger.info("Removing participants from group #{group_id}: #{payload}")
      end
      put!("/groups/#{group_id}/participants", json: payload)
    end

    sig { params(message_id: String, chat_id: String, sender_id: String).void }
    def delete_message(message_id:, chat_id:, sender_id:)
      unless perform_deliveries?
        tag_logger do
          logger.info("Skipping deleting message #{message_id}")
        end
        return
      end

      tag_logger do
        logger.info("Deleting message #{message_id} (#{{ chat_id:, sender_id: }})")
      end
      suppress(HTTP::ParseError) do
        post!("/messages/#{message_id}/delete", json: {
          "chatId" => chat_id,
          "senderId" => sender_id,
        })
      end
    end

    sig { params(group_id: String).returns(T.nilable(String)) }
    def community_id(group_id:)
      data = get!("/groups/#{group_id}")
      data["communityId"]
    end

    sig { params(community_id: String, participant_id: String).returns(T::Boolean) }
    def community_admin?(community_id:, participant_id:)
      data = get!("/communities/#{community_id}")
      participants = T.let(
        data.fetch("participants"),
        T::Array[T::Hash[String, T.untyped]],
      )
      if (participant = participants.find { |p| p["id"] == participant_id })
        !!participant["isAdmin"]
      else
        false
      end
    end

    sig { params(group_id: String, participant_id: String).returns(T::Boolean) }
    def group_admin?(group_id:, participant_id:)
      data = get!("/groups/#{group_id}")
      participants = T.let(
        data.fetch("participants"),
        T::Array[T::Hash[String, T.untyped]],
      )
      if (participant = participants.find { |p| p["id"] == participant_id })
        !!participant["isAdmin"]
      else
        false
      end
    end

    private

    # == Helpers ==

    sig { returns(T::Boolean) }
    def perform_deliveries?
      Rails.env.production?
    end

    sig { params(path: String, options: T.untyped).returns(T.untyped) }
    def get!(path, **options)
      response = @session.get(path, **options)
      check_response!(response)
      response.parse
    end

    sig { params(path: String, options: T.untyped).returns(T.untyped) }
    def put!(path, **options)
      response = @session.put(path, **options)
      check_response!(response)
      response.parse
    end

    sig { params(path: String, options: T.untyped).returns(T.untyped) }
    def post!(path, **options)
      response = @session.post(path, **options)
      check_response!(response)
      response.parse
    end

    sig { params(response: HTTP::Response).void }
    def check_response!(response)
      unless response.status.success?
        raise BadResponse, response
      end
    end
  end
end
