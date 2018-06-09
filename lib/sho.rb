require 'tilt'

module Sho
  class Configurator
    def initialize(host)
      @host = host
    end

    def template(name, template, **options)
      @host.__send__(:define_method, name) do |**|
        Tilt.new(template).render(self)
      end
    end
  end
end