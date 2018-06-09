# frozen_string_literal: true

require 'tilt'

module Sho
  def self.included(mod)
    mod.define_singleton_method(:sho) {
      @__sho_configurator__ ||= Configurator.new(mod)
    }
  end

  # rubocop:disable Lint/UnderscorePrefixedVariableName
  class Configurator
    attr_reader :host
    attr_accessor :base_folder

    def initialize(host)
      @host = host
    end

    def template(name, template, *mandatory, _layout: nil, **optional)
      define_template_method(
        name,
        File.join(base_folder || Dir.pwd, template),
        *mandatory,
        _layout: _layout,
        **optional
      )
    end

    def template_relative(name, template, *mandatory, _layout: nil, **optional)
      base = File.dirname(caller(1..1).first.split(':').first)
      define_template_method(
        name,
        File.join(base, template),
        *mandatory,
        _layout: _layout,
        **optional
      )
    end

    def template_inline(name, *_mandatory, _layout: nil, **options)
      kind, template = options.detect { |key,| Tilt.registered?(key.to_s) }
      template or fail ArgumentError, "No known templates found in #{options.keys}"

      @host.__send__(:define_method, name) do |**locals|
        tilt = Tilt.default_mapping[kind].new { template }
        if _layout
          __send__(_layout) { tilt.render(self, **locals) }
        else
          tilt.render(self, **locals)
        end
      end
    end

    alias inline_template template_inline

    private

    def define_template_method(name, path, *mandatory, _layout:, **optional)
      arguments = ArgumentValidator.new(*mandatory, **optional)
      @host.__send__(:define_method, name) do |**locals|
        tilt = Tilt.new(path)
        locals = arguments.call(**locals)
        if _layout
          __send__(_layout) { tilt.render(self, **locals) }
        else
          tilt.render(self, **locals)
        end
      end
    end
  end
  # rubocop:enable Lint/UnderscorePrefixedVariableName

  class ArgumentValidator
    def initialize(*mandatory, **optional)
      mandatory.all? { |m| m.is_a?(Symbol) } or
        fail ArgumentError, 'Mandatory arguments should be send as array of symbols'
      @mandatory = mandatory
      @optional = optional
    end

    def call(**params)
      (@mandatory - params.keys).tap do |missing|
        missing.empty? or fail ArgumentError, "missing keywords: #{missing.join(', ')}"
      end
      (params.keys - @mandatory - @optional.keys).tap do |unknown|
        unknown.empty? or fail ArgumentError, "unknown keywords: #{unknown.join(', ')}"
      end
      params.merge(@optional.reject { |key,| params.key?(key) })
    end
  end
end
