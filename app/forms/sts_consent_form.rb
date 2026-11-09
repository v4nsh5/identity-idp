# frozen_string_literal: true

# Captures a user's consent for an STS (token exchange) broker service provider to act at a
# target service provider, and persists it to the user_consent_sts table.
class StsConsentForm
  include ActiveModel::Model
  include ActionView::Helpers::TranslationHelper

  CONSENT_GIVEN_VALUE = 'consented'

  validate :validate_consent_given

  attr_reader :consent_given

  def initialize(user:, broker_issuer:, target_app:)
    @user = user
    @broker_issuer = broker_issuer
    @target_app = target_app
  end

  def submit(params)
    @consent_given = params[:consent_given] == CONSENT_GIVEN_VALUE

    if valid?
      process_successful_submission
      self.success = true
    else
      self.success = false
    end

    FormResponse.new(success: success, errors: errors)
  end

  private

  attr_accessor :success
  attr_reader :user, :broker_issuer, :target_app

  def validate_consent_given
    return if @consent_given

    errors.add(
      :consent_given,
      t('forms.validation.required_checkbox'),
      type: :required_checkbox,
    )
  end

  def process_successful_submission
    consent = UserConsentSts.find_or_initialize_by(user:, broker_issuer:, target_app:)
    # Refresh the consent timestamp so a previously expired consent becomes valid again.
    consent.created_at = Time.zone.now if consent.persisted?
    consent.save!
  end
end
