# frozen_string_literal: true

module Sho
  # rubocop:disable Lint/UnderscorePrefixedVariableName

  # Main Sho object providing rendering method creation API.
  #
  # There are three ways to create rendering methods:
  #
  # * {#template}: template is looked up relative to main folder, or {#base_folder};
  # * {#template_relative}: template is looked up relative to current class' folder;
  # * {#inline_template}: template is provided inline as a Ruby string/heredoc.
  #
  # @example
  #   class AnyClass
  #     include Sho
  #
  #     # `sho` returns an instance of Configurator
  #     sho.template :rendering_method_name, 'path/to/template.slim', :param1, param2: default_value
  #   end
  #
  class Configurator
    # @private
    attr_reader :host

    # @return [String, nil] folder to look templates at for {#template} method. `nil` by default,
    #   meaning application's current folder (`Dir.pwd`).
    attr_accessor :base_folder

    # @return [true, false] cache templates upon initialization. `true` by default.
    attr_accessor :cache

    # @private
    def initialize(host)
      @host = host
      @cache = true
    end

    # Generates instance method named `name` in a host module, which renders template from
    # `template`.
    # Instance of the host class is passed as a template scope on rendering.
    #
    # Template is looked up relative to application's main folder, or {#base_folder}.
    #
    # @example
    #   # generates method with signature #profile()
    #   sho.template :profile, 'app/views/users/profile.slim'
    #
    #   # generates method with signature #profile(context:, detailed: false)
    #   # `context` and `detailed` vairables are accessible inside template.
    #   sho.template :profile, 'app/views/users/profile.slim', :context, detailed: false
    #
    # @param name [Symbol] name of method to generate;
    # @param template [String] path to template to render;
    # @param _layout [Symbol, nil] name of method which provides layout (wraps results of current
    #   method);
    # @param mandatory [Array<Symbol>] list of mandatory params;
    # @param optional [Hash{Symbol => Object}] list of optional params and their default values
    def template(name, template, *mandatory, _layout: nil, **optional)
      tpl = proc { Tilt.new(File.expand_path(template, base_folder || Dir.pwd)) }

      define_template_method(name, tpl, mandatory, optional, _layout)
    end

    # Like {#template}, but looks up template relative to host module path. Allows to structure
    # views like:
    #
    # ```
    # app/
    # +- view_models/
    #    +- users.rb   # calls sho.template_relative :profile, 'users/profile.slim'
    #    +- users/
    #       +- profile.slim
    # ```
    #
    # @param name [Symbol] name of method to generate;
    # @param template [String] path to template to render;
    # @param _layout [Symbol, nil] name of method which provides layout (wraps results of current
    #   method);
    # @param mandatory [Array<Symbol>] list of mandatory params;
    # @param optional [Hash{Symbol => Object}] list of optional params and their default values
    def template_relative(name, template, *mandatory, _layout: nil, **optional)
      base = File.dirname(caller(1..1).first.split(':').first)
      tpl = proc { Tilt.new(File.expand_path(template, base)) }

      define_template_method(name, tpl, mandatory, optional, _layout)
    end

    # Inline rendering method definition, useful in decorators and other contexts with small
    # templates.
    #
    # @example
    #    sho.inline_template :badge,
    #      slim: <<~SLIM
    #        span.badge
    #          span.name = user.name
    #          i.role(class: user.role)
    #      SLIM
    #
    # @param name [Symbol] name of method to generate;
    # @param _layout [Symbol, nil] name of method which provides layout (wraps results of current
    #   method);
    # @param mandatory [Array<Symbol>] list of mandatory params;
    # @param options [Hash{Symbol => Object}] list of optional params and their default values +
    #   template to render (passed in a key named `slim:` or `erb:` or `haml:`, and so on).
    def template_inline(name, *mandatory, _layout: nil, **options)
      kind, template = options.detect { |key,| Tilt.registered?(key.to_s) }
      template or fail ArgumentError, "No known templates found in #{options.keys}"
      optional = options.reject { |key,| key == kind }
      tpl = Tilt.default_mapping[kind].new { template }

      define_template_method(name, tpl, mandatory, optional, _layout)
    end

    alias inline_template template_inline

    private

    def define_template_method(name, tilt, mandatory, optional, layout) # rubocop:disable Metrics/MethodLength
      arguments = ArgumentValidator.new(*mandatory, **optional)
      tilt = tilt.call if cache && tilt.respond_to?(:call)

      @host.__send__(:define_method, name) do |**locals, &block|
        locals = arguments.call(**locals)
        tpl = tilt.respond_to?(:call) ? tilt.call : tilt

        if layout
          __send__(layout) { tpl.render(self, **locals) }
        else
          tpl.render(self, **locals, &block)
        end
      end
    end
  end
  # rubocop:enable Lint/UnderscorePrefixedVariableName
end
