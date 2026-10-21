# Switches an admin can flip from the app, kept in the database so they survive deploys.
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.enabled?(key, default: true)
    record = find_by(key: key)
    record ? record.value == "on" : default
  end

  def self.switch(key, on) = store(key, on ? "on" : "off")

  def self.fetch(key) = find_by(key: key)&.value

  def self.store(key, value)
    record = find_or_initialize_by(key: key)
    record.update!(value: value) unless record.persisted? && record.value == value
  end

  def self.decay_enabled? = enabled?("decay")
end
