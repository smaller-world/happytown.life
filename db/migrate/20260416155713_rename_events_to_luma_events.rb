class RenameEventsToLumaEvents < ActiveRecord::Migration[8.1]
  def change
    rename_table :events, :luma_events
    rename_column :luma_events, :luma_url, :url
  end
end
