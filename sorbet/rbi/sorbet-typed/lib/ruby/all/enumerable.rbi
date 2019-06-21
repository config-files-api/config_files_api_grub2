# -*- ruby -*-
# typed: strong
module Enumerable
  sig do
    type_parameters(:U)
      .params(
        acc:   T.type_parameter(:U),
        block: T.proc.params(
          item:   T.untyped,
          result: T.type_parameter(:U)
        )
        .void
      )
      .returns(T.type_parameter(:U))
  end
  def each_with_object(acc, &block); end
end
