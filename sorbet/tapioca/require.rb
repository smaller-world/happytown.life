# typed: ignore # rubocop:disable Sorbet/TrueSigil
# frozen_string_literal: true

# Add your extra requires here (`bin/tapioca require` can be used to bootstrap
# this list)

require "tapioca/dsl/helpers/active_record_constants_helper"
require "ruby_llm/active_record/acts_as"

::ActiveRecord::Base.include(RubyLLM::ActiveRecord::ActsAs) # rubocop:disable Rails/ActiveSupportOnLoad
