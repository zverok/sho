# frozen_string_literal: true

require 'tilt'

# Sho is a small, non-framework view library based on Tilt.
#
# `sho` object in an example below is an instance of {Sho::Configurator}, look at its docs to
# understand how to define rendering methods.
#
# @example
#   class AnyClass
#     include Sho
#
#     sho.template :rendering_method_name, 'path/to/template.slim', :param1, param2: default_value
#   end
#
#   # with instance of AnyClass:
#   object.rendering_method_name(param1: 'foo', param2: 'bar') # => template.slim rendered
#
module Sho
  # Adds `#sho` method (access to instance of {Sho::Configurator}) to class/module `Sho` is
  # included into.
  def self.included(mod)
    mod.define_singleton_method(:sho) {
      @__sho_configurator__ ||= Configurator.new(mod)
    }
  end
end

require_relative 'sho/argument_validator'
require_relative 'sho/configurator'
