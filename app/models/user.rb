class User < ApplicationRecord
  # 特别强调：这里的顺序不能打乱，新的角色依次放在最后
  ROLES = %i(super_user
             admin
             personal_user
             company_user)

  SUPER_USERS = ENV.fetch('SUPER_USERS', []).split(',')

  validates_uniqueness_of :name, :git_token, allow_blank: true
  validates :name, format: { with: /\A(?=.{2,20}$)(?!.*[_]{2})(?!.*[-]{2})[a-zA-Z0-9_-]+\Z/ }, allow_blank: true

  validate :unique_name_by_organization

  has_many :spaces, dependent: :destroy
  has_many :org_memberships, dependent: :destroy
  has_many :organizations, through: :org_memberships
  has_many :comments, dependent: :destroy
  has_many :models, as: :owner
  has_many :created_models, class_name: 'Model', foreign_key: :creator_id
  has_many :created_organizations, class_name: 'Organization', foreign_key: :creator_id
  has_many :ssh_keys, dependent: :destroy

  after_save :sync_to_starhub_server

  has_many :datasets, as: :owner
  has_many :created_datasets, class_name: 'Dataset', foreign_key: :creator_id

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
    has_role?('super_user') || SUPER_USERS.include?(phone)
  end

  def admin?
    has_role?('admin') || super_user?
  end

  def company_user?
    has_role?('company_user')
  end

  def display_name
    nickname.presence || name.presence || phone.presence || login_identity.presence
  end

  def avatar_url
    if avatar.to_s.match(/^avatar\/*/)
      # retrive the image temp url from aliyun
      AliyunOss.instance.download avatar
    elsif avatar.present?
      avatar
    else
      nil
    end
  end

  def available_namespaces
    org_names = organizations.includes(:org_memberships).where.not(org_memberships: {role: 'read'}).pluck(:id, :name).uniq
    [["#{id}_User", name], *org_names.map { |id, name| ["#{id}_Organization", name] }]
  end

  def org_role org
    org_memberships.find_by(organization: org)&.role
  end

  def starhub_synced!
    self.starhub_synced = true
    self.save
  end

  def starhub_synced?
    starhub_synced == true
  end

  def sync_to_starhub_server
    Starhub.api.text_secure_check('nickname_detection', "#{name} #{nickname} #{email}")

    if starhub_synced?
      res = Starhub.api.update_user(name, nickname, email)
      raise StarhubError, res.body unless res.success?
    else
      res = Starhub.api.create_user(name, nickname, email)
      raise StarhubError, res.body unless res.success?
      starhub_synced!
    end
  end

  def as_json options = nil
    {
      id: id,
      name: name,
      nickname: nickname,
      email: email,
      phone: phone,
      avatar: avatar_url
    }
  end

  private

  def unique_name_by_organization
    errors.add(:name, 'is already taken') if Organization.where(name: name).exists?
  end
end
