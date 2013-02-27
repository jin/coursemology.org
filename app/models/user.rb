class User < ActiveRecord::Base
  acts_as_paranoid

  before_create :set_default_role
  before_create :set_default_profile_pic

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :display_name, :name, :profile_photo_url, :system_role_id

  has_many :user_courses
  has_many :courses, through: :user_courses

  belongs_to :system_role, class_name: "Role"

  def is_admin?
    return self.system_role == Role.find_by_name('superuser')
  end

  def is_lecturer?
    return self.is_admin? || self.system_role == Role.find_by_name('lecturer')
  end

  def self.admins
    return User.joins(:system_role).where('roles.name' => 'superuser')
  end

  private
  def set_default_role
    if !self.system_role
      self.system_role = Role.find_by_name('normal')
    end
  end

  def set_default_profile_pic
    if !self.profile_photo_url
      self.profile_photo_url =
        'https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash4/c178.0.604.604/s160x160/252231_1002029915278_1941483569_n.jpg'
    end
  end
end
