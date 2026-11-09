require 'rails_helper'

RSpec.describe UserConsentSts do
  let(:user) { create(:user) }
  let(:broker_issuer) { 'broker' }

  describe 'associations' do
    it 'belongs to a user' do
      consent = described_class.new(user:, broker_issuer:, target_app: 'issuer')

      expect(consent.user).to eq(user)
    end
  end

  describe 'validations' do
    it 'requires a user' do
      consent = described_class.new(user: nil, broker_issuer:, target_app: 'issuer')

      expect(consent).not_to be_valid
      expect(consent.errors[:user]).to be_present
    end

    it 'requires broker_issuer' do
      consent = described_class.new(user:, broker_issuer: nil, target_app: 'issuer')

      expect(consent).not_to be_valid
      expect(consent.errors[:broker_issuer]).to be_present
    end

    it 'requires target_app' do
      consent = described_class.new(user:, broker_issuer:, target_app: nil)

      expect(consent).not_to be_valid
      expect(consent.errors[:target_app]).to be_present
    end

    it 'is valid with a user, broker_issuer and target_app' do
      consent = described_class.new(user:, broker_issuer:, target_app: 'issuer')

      expect(consent).to be_valid
    end
  end

  describe 'uniqueness' do
    it 'enforces uniqueness of user + broker_issuer + target_app at the database level' do
      described_class.create!(user:, broker_issuer:, target_app: 'issuer')

      expect do
        described_class.create!(user:, broker_issuer:, target_app: 'issuer')
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows the same user for a different target_app' do
      described_class.create!(user:, broker_issuer:, target_app: 'app-a')

      expect do
        described_class.create!(user:, broker_issuer:, target_app: 'app-b')
      end.not_to raise_error
    end

    it 'allows the same user and target_app for a different broker' do
      described_class.create!(user:, broker_issuer: 'broker-a', target_app: 'issuer')

      expect do
        described_class.create!(user:, broker_issuer: 'broker-b', target_app: 'issuer')
      end.not_to raise_error
    end
  end

  describe '#unexpired?' do
    before do
      allow(IdentityConfig.store).to receive(:sts_consent_expiration_in_days).and_return(365)
    end

    it 'is true when consent is within the expiration window' do
      consent = described_class.create!(user:, broker_issuer:, target_app: 'issuer')

      expect(consent.unexpired?).to eq(true)
    end

    it 'is false when consent is older than the expiration window' do
      consent = described_class.create!(user:, broker_issuer:, target_app: 'issuer')
      consent.update!(created_at: 366.days.ago)

      expect(consent.unexpired?).to eq(false)
    end
  end

  describe '.unexpired' do
    before do
      allow(IdentityConfig.store).to receive(:sts_consent_expiration_in_days).and_return(365)
    end

    it 'includes consents within the expiration window' do
      consent = described_class.create!(user:, broker_issuer:, target_app: 'issuer')

      expect(described_class.unexpired).to eq([consent])
    end

    it 'excludes consents older than the expiration window' do
      consent = described_class.create!(user:, broker_issuer:, target_app: 'issuer')
      consent.update!(created_at: 366.days.ago)

      expect(described_class.unexpired).to be_empty
    end
  end

  describe '.with_broker' do
    it 'excludes consents recorded before consent named the broker' do
      consent = described_class.create!(user:, broker_issuer:, target_app: 'issuer')
      legacy = described_class.new(user:, broker_issuer: nil, target_app: 'issuer')
      legacy.save!(validate: false)

      expect(described_class.with_broker).to eq([consent])
    end
  end

  describe '.consent_valid?' do
    before do
      allow(IdentityConfig.store).to receive(:sts_consent_expiration_in_days).and_return(365)
    end

    it 'is false when no consent record exists' do
      expect(described_class.consent_valid?(user:, broker_issuer:, target_app: 'issuer'))
        .to eq(false)
    end

    it 'is true when an unexpired consent exists for the broker and target' do
      described_class.create!(user:, broker_issuer:, target_app: 'issuer')

      expect(described_class.consent_valid?(user:, broker_issuer:, target_app: 'issuer'))
        .to eq(true)
    end

    it 'is false for another broker at the same target' do
      described_class.create!(user:, broker_issuer:, target_app: 'issuer')

      expect(
        described_class.consent_valid?(user:, broker_issuer: 'other-broker', target_app: 'issuer'),
      ).to eq(false)
    end

    it 'is false without a broker, even when a consent recorded without one exists' do
      described_class.new(user:, broker_issuer: nil, target_app: 'issuer').save!(validate: false)

      expect(described_class.consent_valid?(user:, broker_issuer: nil, target_app: 'issuer'))
        .to eq(false)
    end

    it 'is false when the consent is expired' do
      consent = described_class.create!(user:, broker_issuer:, target_app: 'issuer')
      consent.update!(created_at: 366.days.ago)

      expect(described_class.consent_valid?(user:, broker_issuer:, target_app: 'issuer'))
        .to eq(false)
    end
  end
end
