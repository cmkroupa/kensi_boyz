# Runs the nightly backup now instead of waiting for the schedule.
class BackupsController < ApplicationController
  before_action :require_admin

  def create
    DatabaseBackupJob.perform_later
    redirect_to admin_path, notice: "Backup started. Refresh in a minute to see it."
  end
end
