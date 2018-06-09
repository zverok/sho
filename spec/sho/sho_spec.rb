# frozen_string_literal: true

RSpec.describe Sho do
  include FakeFS::SpecHelpers

  subject(:view) { Class.new.include(described_class) }

  its(:sho) { is_expected.to be_a Sho::Configurator }
  its(:'sho.host') { is_expected.to eq view }
end
