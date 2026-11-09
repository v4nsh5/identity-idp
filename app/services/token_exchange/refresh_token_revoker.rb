# frozen_string_literal: true

module TokenExchange
  # Ends a person's refresh token families when something outside the broker means it should no
  # longer get subject tokens on their behalf. The broker's own sign-out uses the revocation
  # endpoint instead.
  module RefreshTokenRevoker
    # Security events after which no broker should keep acting for the person without a new
    # sign-in. Account reinstatement, email changes and reproofing aren't among them.
    REVOKING_SECURITY_EVENTS = [
      PushNotification::AccountDisabledEvent,
      PushNotification::AccountPurgedEvent,
      PushNotification::IdentifierRecycledEvent,
      PushNotification::MfaLimitAccountLockedEvent,
      PushNotification::PasswordResetEvent,
      PushNotification::RecoveryActivatedEvent,
      PushNotification::RecoveryInformationChangedEvent,
    ].freeze

    module_function

    # @param event [Object] a PushNotification event
    def revoke_for_security_event(event)
      return unless REVOKING_SECURITY_EVENTS.include?(event.class)
      return if event.user.blank?

      revoke(TokenExchangeRefreshToken.where(user_id: event.user.id), reason: 'security_event')
    end

    # The person disconnected the broker from their account.
    def revoke_for_broker(user_id:, broker_issuer:)
      revoke(
        TokenExchangeRefreshToken.where(user_id:, broker_issuer:),
        reason: 'service_provider_disconnected',
      )
    end

    # The person revoked a broker's delegation consent for a target, so that broker's families
    # whose sign-in asked for the target can no longer be refreshed.
    def revoke_for_target(user:, broker_issuer:, target_app:)
      target = IdentityConfig.store.token_exchange_allowed_targets
        .find { |allowed| allowed[:issuer] == target_app }
      return 0 if target.blank?

      target_scope = "#{TokenExchange::Constants::SCOPE_PREFIX}#{target.fetch(:scope)}"
      families = TokenExchangeRefreshToken.unrevoked.where(user_id: user.id, broker_issuer:)
        .pluck(:family_id, :scope)
        .select { |_family_id, scope| scope.to_s.split(' ').include?(target_scope) }
        .map(&:first)

      TokenExchangeRefreshToken.revoke_families!(families.uniq, reason: 'consent_revoked')
    end

    def revoke(scope, reason:)
      families = scope.unrevoked.distinct.pluck(:family_id)
      return 0 if families.empty?

      TokenExchangeRefreshToken.revoke_families!(families, reason:)
    end
    private_class_method :revoke
  end
end
