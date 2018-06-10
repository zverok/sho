# frozen_string_literal: true

require 'tilt'

module Sho
  def self.included(mod)
    mod.define_singleton_method(:sho) {
      @__sho_configurator__ ||= Configurator.new(mod)
    }
  end
end
