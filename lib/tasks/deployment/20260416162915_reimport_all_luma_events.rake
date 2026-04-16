# frozen_string_literal: true

namespace :after_party do
  desc "Deployment task: reimport_all_luma_events"
  task reimport_all_luma_events: :environment do
    puts "Running deploy task 'reimport_all_luma_events'"

    # Put your task implementation HERE.
    LumaEvent.destroy_all
    LumaEvent.import

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create(version: AfterParty::TaskRecorder.new(__FILE__).timestamp)
  end
end
