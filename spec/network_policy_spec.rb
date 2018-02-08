# frozen_string_literal: true

require 'xlsx_to_k8s_network_policy'

RSpec.describe NetworkPolicy do
  describe '.initialize' do
    it 'validates the name' do
      expect do
        NetworkPolicy.new('not valid', nil)
      end.to raise_error %(Invalid name "not valid". Must consist of [a-z_-]+)
      expect do
        NetworkPolicy.new('Front-end', nil)
      end.to raise_error %(Invalid name "Front-end". Must consist of [a-z_-]+)
      expect do
        NetworkPolicy.new('front-end', nil)
      end.to_not raise_error
    end
  end
end
