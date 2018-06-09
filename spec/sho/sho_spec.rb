RSpec.describe Sho do
  include FakeFS::SpecHelpers

  let(:view) { Class.new }
  let(:sho) { Sho::Configurator.new(view) }
  let(:object) { view.new }

  describe '#template' do
    let(:args) { [] }
    before { sho.template :test, 'fake.slim', *args }

    it { expect(view.instance_methods).to include(:test) }

    describe 'rendering' do
      before {
        # It is handled by FakeFS, no real disk touched
        File.write 'fake.slim', template
      }
      subject { object.test(**params) }

      let(:params) { {} }
      let(:template) { 'p It works!' }

      it { is_expected.to eq '<p>It works!</p>' }

      describe 'context passing' do
        let(:template) { 'p It #{action}!' }
        before {
          allow(object).to receive(:action).and_return('rules')
        }

        it { is_expected.to eq '<p>It rules!</p>' }
      end

      describe 'params passing' do
        let(:args) { [:name, title: 'Mr.'] }
        let(:template) { 'p Hello #{title} #{name}!' }
        let(:params) { {name: 'Jones', title: 'Dr.'} }

        it { is_expected.to eq '<p>Hello Dr. Jones!</p>' }

        xcontext 'with default args' do
          let(:params) { {name: 'Jones'} }
          it { is_expected.to eq '<p>Hello, Mr. Jones!</p>' }
        end
      end

      describe 'params validation'

      describe 'template lookup' do
        context 'when non-default folder set' do
          before {
            sho.base_folder = 'app/views/details'
            # previous call was before base_folder change
            sho.template :test, 'fake.slim', *args
            FileUtils.rm 'fake.slim'
            FileUtils.mkdir_p 'app/views/details'
            File.write 'app/views/details/fake.slim', template
          }

          it { is_expected.to eq '<p>It works!</p>' }
        end
      end
    end
  end

  describe '#template_relative'
  describe '#template_inline'
end