# typed: true

module Rails
  class << self
    sig do
      returns(T.any(ActiveSupport::Logger, ActiveSupport::BroadcastLogger))
    end
    def logger; end
  end

  class Command::Base; end
end
