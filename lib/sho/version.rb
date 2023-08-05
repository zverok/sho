# frozen_string_literal: true

module Sho
  MAJOR = 0
  MINOR = 1
  PATCH = 2
  PRE = nil
  VERSION = [MAJOR, MINOR, PATCH, PRE].compact.join('.')
end
