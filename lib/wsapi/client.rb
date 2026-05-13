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
        logger.debug("Sending message: #{payload}")
      end
      post!("/messages/text", json: payload)
    end

    sig { params(community_id: String, participants: T::Array[String]).void }
    def remove_community_participants(community_id:, participants:)
      unless perform_deliveries?
        tag_logger do
          logger.info(
            "Skipping removing participants from community " \
              "#{community_id}: #{participants}",
          )
        end
        return
      end

      payload = { participants:, action: "remove" }
      tag_logger do
        logger.debug("Removing participants from community #{community_id}: #{payload}")
      end
      post!("/communities/#{community_id}/participants/remove", json: payload)
    end

    sig { params(group_id: String).returns(T.nilable(String)) }
    def community_id(group_id:)
      data = get!("/groups/#{group_id}")
      data["communityId"]
    end

    sig { params(community_id: String, participant: String).returns(T::Boolean) }
    def community_admin?(community_id:, participant:)
      data = get!("/communities/#{community_id}")
      participants = T.let(data.fetch("participants"), T::Array[String])
      participants.any? { |participant| participant["isAdmin"] }
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
