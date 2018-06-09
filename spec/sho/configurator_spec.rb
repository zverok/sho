RSpec.describe Sho::Configurator do
  include FakeFS::SpecHelpers

  let(:view) { Class.new }
  let(:sho) { described_class.new(view) }
  let(:object) { view.new }

  before {
    FileUtils.mkdir_p REAL_PWD
    Dir.chdir REAL_PWD # Sometimes in tests we work with "real path of current file"
  }

  describe '#template' do
    before { sho.template :test, 'fake.slim', *args }
    let(:args) { [] }

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
      end

      describe 'params validation' do
        let(:args) { [:name, title: 'Mr.'] }
        let(:template) { 'p Hello #{title} #{name}!' }

        context 'mandatory arguments missing' do
          let(:params) { {title: 'Dr.'} }

          its_block { is_expected.to raise_error ArgumentError }
        end

        context 'unknown argument' do
          let(:params) { {name: 'Jones', tilte: 'Dr.'} }

          its_block { is_expected.to raise_error ArgumentError }
        end

        context 'with default args' do
          let(:params) { {name: 'Jones'} }
          it { is_expected.to eq '<p>Hello Mr. Jones!</p>' }
        end
      end

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

      describe 'layout' do
        let(:args) { [_layout: :laymeout] }
        before {
          class << object
            def laymeout
              'before ' + yield + ' after'
            end
          end
        }

        it { is_expected.to eq 'before <p>It works!</p> after' }
      end
    end
  end

  describe '#template_relative' do
    before { sho.template_relative :test, 'fake.slim', *args }
    let(:args) { [] }

    it { expect(view.instance_methods).to include(:test) }

    describe 'rendering' do
      before {
        FileUtils.mkdir_p 'spec/sho'
        File.write 'spec/sho/fake.slim', template
      }
      subject { object.test(**params) }
      let(:params) { {} }
      let(:template) { 'p It works!' }

      it { is_expected.to eq '<p>It works!</p>' }
    end
  end

  describe '#template_inline' do
    before { sho.template_inline :test, *args }
    let(:args) { [{slim: 'p It works!'}] }

    it { expect(view.instance_methods).to include(:test) }

    describe 'rendering' do
      subject { object.test(**params) }
      let(:params) { {} }

      it { is_expected.to eq '<p>It works!</p>' }
    end
  end
end