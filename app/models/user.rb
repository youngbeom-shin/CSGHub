class User < ApplicationRecord
  # 特别强调：这里的顺序不能打乱，新的角色依次放在最后
  ROLES = %i(super_user
             admin
             personal_user
             company_user)

  # user.roles = "super_user"
  # user.roles = ["super_user", "admin"]
  def roles=(*roles)
    roles = [*roles].flatten.map { |r| r.to_sym }
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
    self.save
  end

  def roles
    ROLES.reject do |r|
    ((roles_mask.to_i || 0) & 2**ROLES.index(r)).zero?
    end
  end

  def has_role?(role)
    roles.include?(role.to_sym)
  end

  def super_user?
    has_role?('super_user')
  end

  def admin?
    has_role?('admin')
  end

  def display_name
    name || login_identity
  end
end