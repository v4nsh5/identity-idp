# frozen_string_literal: true

# Records a user's consent for one STS (token exchange) broker to act on their behalf at one target
# service provider. Separate from the general authorization consent captured on the identities
# table. Consent is per broker: consenting through one broker says nothing about another.
class UserConsentSts < ApplicationRecord
  self.table_name = :user_consent_sts

  belongs_to :user, inverse_of: :sts_consents

  validates :user, presence: true
  validates :broker_issuer, presence: true
  validates :target_app, presence: true

  scope :unexpired, -> { where(created_at: consent_expiration.ago..) }
  # Rows from before consent named the broker don't count as consent for any broker.
  scope :with_broker, -> { where.not(broker_issuer: nil) }

  # Returns true when an unexpired consent exists for the given user, broker and target_app.
  def self.consent_valid?(user:, broker_issuer:, target_app:)
    return false if broker_issuer.blank?

    consent = find_by(user:, broker_issuer:, target_app:)
    return false if consent.blank?

    consent.unexpired?
  end

  def unexpired?
    created_at > self.class.consent_expiration.ago
  end

  def self.consent_expiration
    IdentityConfig.store.sts_consent_expiration_in_days.days
  end
end
