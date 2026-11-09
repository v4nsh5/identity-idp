# frozen_string_literal: true

# Delegation consent is given to one broker acting at one target. Rows written before this column
# have no broker; they no longer count as consent, so the person is asked again per broker.
class AddBrokerIssuerToUserConsentSts < ActiveRecord::Migration[8.1]
  def change
    add_column :user_consent_sts, :broker_issuer, :string,
               comment: 'Issuer of the broker SP the user allowed to act for them sensitive=false'
    change_column_comment :user_consent_sts, :target_app,
                          from: 'Issuer of the broker SP the user consented to sensitive=false',
                          to: 'Issuer of the target SP the broker may act at sensitive=false'
  end
end
