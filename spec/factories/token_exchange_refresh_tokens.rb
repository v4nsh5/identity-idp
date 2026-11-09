FactoryBot.define do
  factory :token_exchange_refresh_token do
    transient do
      token { SecureRandom.urlsafe_base64(32) }
    end

    user
    token_digest { TokenExchangeRefreshToken.digest(token) }
    family_id { SecureRandom.uuid }
    broker_issuer { 'urn:gov:gsa:openidconnect:sp:broker' }
    identity_uuid { SecureRandom.uuid }
    scope { 'openid token_exchange:records' }
    ial { 1 }
    dpop_jkt { SecureRandom.urlsafe_base64(32) }
    authenticated_at { 5.minutes.ago }
    family_expires_at { authenticated_at + 12.hours }
    expires_at { 30.minutes.from_now }
  end
end
