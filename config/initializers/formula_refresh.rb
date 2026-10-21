# Rebuild ratings and records on the first server boot after the formula's code
# changes (see FormulaVersion). Skipped for tests, builds and one-off commands.
Rails.application.config.after_initialize do
  next if Rails.env.test? || !defined?(Rails::Server)

  begin
    FormulaVersion.refresh_if_stale if Setting.table_exists?
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.warn("Formula refresh skipped: #{error.message}")
  end
end
