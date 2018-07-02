# frozen_string_literal: true

RSpec.describe Sho::Configurator do
  include FakeFS::SpecHelpers

  let(:view) { Class.new }
  let(:sho) { described_class.new(view) }
  let(:object) { view.new }
  let(:path) { nil }

  before {
    FileUtils.mkdir_p REAL_PWD
    Dir.chdir REAL_PWD # Sometimes in tests we work with "real path of current file"

    # It is handled by FakeFS, no real disk touched
    if path
      FileUtils.mkdir_p File.dirname(path)
      File.write(path, template)
    end
  }

  describe '#template' do
    let(:args) { [] }
    let(:template) { 'p It works!' }

    context 'when default base folder' do
      before { sho.template :test, 'fake.slim', *args }

      let(:path) { 'fake.slim' }

      it { expect(view.instance_methods).to include(:test) }

      describe 'rendering' do
        subject { object.test(**params) }

        let(:params) { {} }

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

          context 'with mandatory arguments missing' do
            let(:params) { {title: 'Dr.'} }

            its_block { is_expected.to raise_error ArgumentError }
          end

          context 'with unknown argument' do
            let(:params) { {name: 'Jones', tilte: 'Dr.'} }

            its_block { is_expected.to raise_error ArgumentError }
          end

          context 'with default args' do
            let(:params) { {name: 'Jones'} }

            it { is_expected.to eq '<p>Hello Mr. Jones!</p>' }
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

        describe 'layout from template' do
          let(:args) { [_layout: :laymeout] }

          before {
            sho.inline_template :laymeout, erb: <<-ERB.strip
              before <%= yield %> after
            ERB
          }

          it { is_expected.to eq 'before <p>It works!</p> after' }
        end

        describe 'cache disabling' do
          subject { File.write(path, 'p No cache!') }

          before {
            sho.cache = false
            # Rewrite method definition without caching
            sho.template :test, 'fake.slim', *args
          }

          its_block {
            is_expected.to change(object, :test).from('<p>It works!</p>').to('<p>No cache!</p>')
          }
        end
      end
    end

    context 'with base_folder' do
      subject { object.test(**params) }

      before {
        sho.base_folder = 'app/views/details'
        sho.template :test, 'fake.slim', *args
      }

      let(:params) { {} }
      let(:path) { 'app/views/details/fake.slim' }

      it { is_expected.to eq '<p>It works!</p>' }
    end
  end

  describe '#template_relative' do
    before { sho.template_relative :test, 'fake.slim', *args }

    let(:args) { [] }
    let(:path) { 'spec/sho/fake.slim' }
    let(:params) { {} }
    let(:template) { 'p It works!' }

    it { expect(view.instance_methods).to include(:test) }

    describe 'rendering' do
      subject { object.test(**params) }

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
