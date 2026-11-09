# frozen_string_literal: true

class AddBrokerToUserConsentStsUniqueIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :user_consent_sts, %i[user_id broker_issuer target_app],
              unique: true,
              name: 'index_user_consent_sts_on_user_broker_target',
              algorithm: :concurrently
    remove_index :user_consent_sts, %i[user_id target_app],
                 unique: true,
                 name: 'index_user_consent_sts_on_user_id_and_target_app',
                 algorithm: :concurrently
  end
end
