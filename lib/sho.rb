require 'tilt'

module Sho
  class Configurator
    attr_accessor :base_folder

    def initialize(host)
      @host = host
    end

    def template(name, template, *arguments)
      path = File.join(base_folder || Dir.pwd, template)
      @host.__send__(:define_method, name) do |**locals|
        Tilt.new(path).render(self, **locals)
      end
    end
  end
end