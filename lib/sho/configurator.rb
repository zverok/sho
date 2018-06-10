# frozen_string_literal: true

module Sho
  # rubocop:disable Lint/UnderscorePrefixedVariableName
  class Configurator
    attr_reader :host
    attr_accessor :base_folder

    def initialize(host)
      @host = host
    end

    def template(name, template, *mandatory, _layout: nil, **optional)
      tpl = Tilt.new(File.expand_path(template, base_folder || Dir.pwd))
      define_template_method(name, tpl, mandatory, optional, _layout)
    end

    def template_relative(name, template, *mandatory, _layout: nil, **optional)
      base = File.dirname(caller(1..1).first.split(':').first)
      tpl = Tilt.new(File.expand_path(template, base))

      define_template_method(name, tpl, mandatory, optional, _layout)
    end

    def template_inline(name, *mandatory, _layout: nil, **options)
      kind, template = options.detect { |key,| Tilt.registered?(key.to_s) }
      template or fail ArgumentError, "No known templates found in #{options.keys}"
      optional = options.reject { |key,| key == kind }
      tpl = Tilt.default_mapping[kind].new { template }

      define_template_method(name, tpl, mandatory, optional, _layout)
    end

    alias inline_template template_inline

    private

    def define_template_method(name, tilt, mandatory, optional, layout)
      arguments = ArgumentValidator.new(*mandatory, **optional)
      @host.__send__(:define_method, name) do |**locals|
        locals = arguments.call(**locals)
        if layout
          __send__(layout) { tilt.render(self, **locals) }
        else
          tilt.render(self, **locals)
        end
      end
    end
  end
  # rubocop:enable Lint/UnderscorePrefixedVariableName
end
