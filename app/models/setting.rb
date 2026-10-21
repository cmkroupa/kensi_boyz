# Switches an admin can flip from the app, kept in the database so they survive deploys.
class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.enabled?(key, default: true)
    record = find_by(key: key)
    record ? record.value == "on" : default
  end

  def self.switch(key, on)
    find_or_initialize_by(key: key).update!(value: on ? "on" : "off")
  end

  def self.decay_enabled? = enabled?("decay")
end
