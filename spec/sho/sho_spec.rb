RSpec.describe Sho do
  include FakeFS::SpecHelpers

  let(:view) { Class.new }
  let(:sho) { Sho::Configurator.new(view) }
  let(:object) { view.new }

  describe '#template' do
    before { sho.template :test, 'fake.slim' }
    it { expect(view.instance_methods).to include(:test) }

    describe 'rendering' do
      before {
        # It is handled by FakeFS, no real disk touched
        File.write 'fake.slim', template
      }
      subject { object.test(**params) }
      let(:params) { {} }
      let(:template) {
        <<~SLIM
          p It works!
        SLIM
      }

      it { is_expected.to eq '<p>It works!</p>' }

      describe 'context passing'
      describe 'params passing'
      describe 'params validation'
      describe 'template lookup'
    end
  end

  describe '#template_relative'
  describe '#template_inline'
end