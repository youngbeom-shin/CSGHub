class SystemConfig < ApplicationRecord
  def oidc_configs=(value)
    self[:oidc_configs] = value.is_a?(String) ? JSON.parse(value) : value
  end

  def feature_flags=(value)
    self[:feature_flags] = value.is_a?(String) ? JSON.parse(value) : value
  end
end