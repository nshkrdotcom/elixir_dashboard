defmodule ElixirDashboard.TestHelpers do
  @moduledoc """
  Shared test helpers using Supertester principles.

  All helpers follow deterministic synchronization patterns with zero blind timing waits.
  """

  @default_timeout 5000
  @default_interval 100

  @doc """
  Polls until a condition is met or timeout is reached.

  Uses deterministic polling (no blind waits). Checks condition every 100ms.

  ## Examples

      # Wait for GenServer state
      assert_eventually(fn ->
        Store.get_slow_endpoints() != []
      end)

      # With custom timeout
      assert_eventually(fn ->
        metrics_count() > 10
      end, timeout: 10_000)

      # With custom message
      assert_eventually(
        fn -> condition() end,
        timeout: 3000,
        message: "Expected condition to be true"
      )
  """
  def assert_eventually(condition_fn, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    interval = Keyword.get(opts, :interval, @default_interval)
    message = Keyword.get(opts, :message, "Condition not met within timeout")

    end_time = System.monotonic_time(:millisecond) + timeout

    poll_until_true(condition_fn, end_time, interval, message)
  end

  defp poll_until_true(condition_fn, end_time, interval, message) do
    if condition_fn.() do
      :ok
    else
      now = System.monotonic_time(:millisecond)

      if now >= end_time do
        raise ExUnit.AssertionError, message: message
      else
        Process.sleep(interval)
        poll_until_true(condition_fn, end_time, interval, message)
      end
    end
  end

  @doc """
  Waits for a process to terminate.

  Returns the termination reason.

  ## Examples

      {:ok, pid} = start_something()
      reason = wait_for_termination(pid, timeout: 5000)
      assert reason in [:normal, :shutdown]
  """
  def wait_for_termination(pid, opts \\ []) when is_pid(pid) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    if Process.alive?(pid) do
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, ^pid, reason} ->
          reason
      after
        timeout ->
          Process.demonitor(ref, [:flush])

          raise ExUnit.AssertionError,
            message: "Process #{inspect(pid)} did not terminate within #{timeout}ms"
      end
    else
      :noproc
    end
  end

  @doc """
  Collects all messages matching a pattern within timeout.

  ## Examples

      messages = collect_messages_matching(
        fn msg -> match?({:progress, _, _}, msg) end,
        timeout: 3000
      )

      assert length(messages) == 5
  """
  def collect_messages_matching(pattern_fn, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    collect_loop(pattern_fn, timeout, [])
  end

  defp collect_loop(_pattern_fn, timeout, acc) when timeout <= 0 do
    Enum.reverse(acc)
  end

  defp collect_loop(pattern_fn, timeout, acc) do
    start_time = System.monotonic_time(:millisecond)

    receive do
      msg ->
        elapsed = System.monotonic_time(:millisecond) - start_time
        remaining = timeout - elapsed

        if pattern_fn.(msg) do
          collect_loop(pattern_fn, remaining, [msg | acc])
        else
          collect_loop(pattern_fn, remaining, acc)
        end
    after
      timeout ->
        Enum.reverse(acc)
    end
  end

  @doc """
  Asserts that values are monotonically increasing.

  ## Examples

      assert_monotonically_increasing([0, 10, 20, 100])
      assert_monotonically_increasing([0, 10, 10, 20])  # Allows equal
      assert_monotonically_increasing([0, 10, 5, 20])   # FAILS
  """
  def assert_monotonically_increasing(values) when is_list(values) do
    values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.each(fn {[a, b], index} ->
      unless b >= a do
        raise ExUnit.AssertionError,
          message:
            "Values not monotonically increasing at index #{index}: #{a} -> #{b}. " <>
              "Full sequence: #{inspect(values)}"
      end
    end)

    :ok
  end

  @doc """
  Flushes all messages from the process mailbox.

  Useful for cleanup between tests.

  ## Examples

      flush_mailbox()
      # Mailbox is now empty
  """
  def flush_mailbox do
    receive do
      _ -> flush_mailbox()
    after
      0 -> :ok
    end
  end

  @doc """
  Waits for a GenServer to be registered with a given name.

  ## Examples

      wait_for_registration(MyGenServer, timeout: 1000)
      assert Process.whereis(MyGenServer) != nil
  """
  def wait_for_registration(name, opts \\ []) do
    assert_eventually(
      fn -> Process.whereis(name) != nil end,
      Keyword.put(opts, :message, "GenServer #{inspect(name)} not registered")
    )
  end

  @doc """
  Generates a unique test ID for process isolation.

  ## Examples

      test_id = unique_test_id()
      topic = "report:" <> test_id
      report_id = "report_" <> test_id
  """
  def unique_test_id do
    make_ref() |> :erlang.phash2() |> to_string()
  end

  @doc """
  Asserts that a list of PIDs are all alive.

  ## Examples

      pids = [pid1, pid2, pid3]
      assert_all_alive(pids)
  """
  def assert_all_alive(pids) when is_list(pids) do
    dead_pids = Enum.filter(pids, &(not Process.alive?(&1)))

    if length(dead_pids) > 0 do
      raise ExUnit.AssertionError,
        message:
          "Expected all processes alive, but #{length(dead_pids)} are dead: #{inspect(dead_pids)}"
    end

    :ok
  end

  @doc """
  Waits for a condition to be true, checking the ElixirTracer storage.

  Convenience wrapper for common ElixirTracer assertion patterns.

  ## Examples

      wait_for_transactions(fn txs -> length(txs) > 5 end)
      wait_for_errors(fn errors -> Enum.any?(errors, &(&1.error_type == "RuntimeError")) end)
  """
  def wait_for_transactions(condition_fn, opts \\ []) do
    assert_eventually(
      fn ->
        transactions = ElixirTracer.Query.get_transactions()
        condition_fn.(transactions)
      end,
      opts
    )
  end

  def wait_for_spans(condition_fn, opts \\ []) do
    assert_eventually(
      fn ->
        spans = ElixirTracer.Query.get_spans()
        condition_fn.(spans)
      end,
      opts
    )
  end

  def wait_for_errors(condition_fn, opts \\ []) do
    assert_eventually(
      fn ->
        errors = ElixirTracer.Query.get_errors()
        condition_fn.(errors)
      end,
      opts
    )
  end

  def wait_for_metrics(condition_fn, opts \\ []) do
    assert_eventually(
      fn ->
        metrics = ElixirTracer.Query.get_metrics()
        condition_fn.(metrics)
      end,
      opts
    )
  end

  def wait_for_events(condition_fn, opts \\ []) do
    assert_eventually(
      fn ->
        events = ElixirTracer.Query.get_custom_events()
        condition_fn.(events)
      end,
      opts
    )
  end
end
