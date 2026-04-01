defmodule Pollard.LockTest do
  use ExUnit.Case

  alias Pollard.Lock.None

  describe "Pollard.Lock.None" do
    test "acquire always returns :ok" do
      assert :ok = None.acquire(nil, [])
    end

    test "release always returns :ok" do
      assert :ok = None.release(nil, [])
    end
  end

  describe "custom lock module" do
    test "can implement the behaviour" do
      defmodule TestLock do
        @behaviour Pollard.Lock

        @impl true
        def acquire(_repo, opts) do
          send(opts[:test_pid], :lock_acquired)
          :ok
        end

        @impl true
        def release(_repo, opts) do
          send(opts[:test_pid], :lock_released)
          :ok
        end
      end

      assert :ok = TestLock.acquire(nil, test_pid: self())
      assert_received :lock_acquired

      assert :ok = TestLock.release(nil, test_pid: self())
      assert_received :lock_released
    end

    test "can signal locked" do
      defmodule LockedLock do
        @behaviour Pollard.Lock

        @impl true
        def acquire(_repo, _opts), do: {:error, :locked}

        @impl true
        def release(_repo, _opts), do: :ok
      end

      assert {:error, :locked} = LockedLock.acquire(nil, [])
    end
  end
end
