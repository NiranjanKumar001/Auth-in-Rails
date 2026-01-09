class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP, message: "Please enter a valid email address" }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase.strip if email.present?
  end

  def password_required?
    new_record? || password.present?
  end
end
