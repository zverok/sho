# frozen_string_literal: true

RSpec.describe Sho::ArgumentValidator do
  subject { validator.method(:call) }

  let(:validator) { described_class.new(:a, :b, c: 1, d: nil) }

  its_call(a: 1, b: 2, c: 3, d: 4) { is_expected.to ret(a: 1, b: 2, c: 3, d: 4) }

  its_call(b: 2, c: 3, d: 4) { is_expected.to raise_error ArgumentError, 'missing keywords: a' }
  its_call(a: 1, b: 2, c: 3) { is_expected.to ret(a: 1, b: 2, c: 3, d: nil) }
  its_call(a: 1, b: 2, d: 4) { is_expected.to ret(a: 1, b: 2, c: 1, d: 4) }

  its_call(a: 1, b: 2, e: 5) { is_expected.to raise_error ArgumentError, 'unknown keywords: e' }
end
