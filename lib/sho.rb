require 'tilt'

module Sho
  class Configurator
    attr_accessor :base_folder

    def initialize(host)
      @host = host
    end

    def template(name, template, *, _layout: nil, **)
      path = File.join(base_folder || Dir.pwd, template)
      @host.__send__(:define_method, name) do |**locals|
        tilt = Tilt.new(path)
        if _layout
          __send__(_layout) { tilt.render(self, **locals) }
        else
          tilt.render(self, **locals)
        end
      end
    end
  end
end