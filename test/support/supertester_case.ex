defmodule ElixirDashboard.SupertesterCase do
  @moduledoc """
  Base test case module using Supertester principles for ElixirDashboard.

  Provides:
  - Zero Process.sleep patterns
  - Deterministic synchronization
  - OTP-aware assertions
  - Automatic cleanup
  - Process isolation

  ## Usage

      defmodule MyTest do
        use ElixirDashboard.SupertesterCase, async: true

        test "my deterministic test" do
          assert_eventually(fn ->
            condition_met?()
          end)
        end
      end
  """

  use ExUnit.CaseTemplate

  using _opts do
    quote do
      import ElixirDashboard.TestHelpers
      import Supertester.Assertions
      import Supertester.OTPHelpers

      # Enable async by default via use option, not moduletag
      @moduletag :capture_log

      # Setup automatic cleanup
      setup do
        # Clear ElixirTracer data before each test
        ElixirTracer.Query.clear_all()

        # Return test context
        :ok
      end
    end
  end
end
