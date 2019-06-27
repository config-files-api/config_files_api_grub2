# frozen_string_literal: true

# typed: false
require "sorbet-runtime"

# Test
class C
  extend T::Sig

  sig { params(array: T::Array[Integer]).returns(String) }
  def sum_ewo(array)
    array.each_with_object(String.new) do |i, acc|
      acc << i.to_s
      nil
    end
  end

  sig { params(array: T::Array[Integer]).returns(String) }
  def sum_r(array)
    array.reduce(String.new) do |acc, i|
      acc << i.to_s
    end
  end
end

a = [1, 2, 3]
puts C.new.sum_r(a)
puts C.new.sum_ewo(a)
