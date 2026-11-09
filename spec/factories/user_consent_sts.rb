FactoryBot.define do
  factory :user_consent_sts do
    user
    broker_issuer { "urn:gov:gsa:openidconnect:sp:broker:#{SecureRandom.hex(4)}" }
    target_app { "urn:gov:gsa:openidconnect:sp:target:#{SecureRandom.hex(4)}" }
  end
end
