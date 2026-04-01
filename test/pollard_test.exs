defmodule PollardTest do
  use ExUnit.Case

  describe "transform macro" do
    test "registers transforms in definition order" do
      defmodule TestTransform do
        use Pollard

        transform "first" do
          :first
        end

        transform "second" do
          :second
        end

        transform "third" do
          :third
        end
      end

      transforms = TestTransform.__pollard_transforms__()
      names = Enum.map(transforms, fn {name, _func} -> name end)

      assert names == ["first", "second", "third"]
    end

    test "transform functions are callable and return block result" do
      defmodule CallableTransform do
        use Pollard

        transform "returns value" do
          42
        end
      end

      [{_name, func_name}] = CallableTransform.__pollard_transforms__()
      assert apply(CallableTransform, func_name, []) == 42
    end

    test "multiple transforms get distinct function names" do
      defmodule DistinctTransform do
        use Pollard

        transform "alpha" do
          :alpha
        end

        transform "beta" do
          :beta
        end
      end

      transforms = DistinctTransform.__pollard_transforms__()
      func_names = Enum.map(transforms, fn {_name, func} -> func end)

      assert length(Enum.uniq(func_names)) == 2
    end
  end
end
