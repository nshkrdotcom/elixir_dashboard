defmodule ElixirDashboard.Fixtures do
  @moduledoc """
  Fixture data generator for ElixirTracer integration testing.

  Generates realistic errors, metrics, and custom events for dashboard demonstration.

  ## Usage

      # Generate all fixture data
      ElixirDashboard.Fixtures.generate_all()

      # Generate specific types
      ElixirDashboard.Fixtures.generate_errors(5)
      ElixirDashboard.Fixtures.generate_metrics()
      ElixirDashboard.Fixtures.generate_events(10)
  """

  @doc """
  Generate all types of fixture data.
  """
  def generate_all(opts \\ []) do
    error_count = Keyword.get(opts, :errors, 5)
    event_count = Keyword.get(opts, :events, 10)

    generate_errors(error_count)
    generate_metrics()
    generate_events(event_count)

    %{
      errors: error_count,
      metrics: "generated",
      events: event_count
    }
  end

  @doc """
  Generate realistic error traces with stack traces.
  """
  def generate_errors(count \\ 5) do
    error_templates = [
      %{
        type: "Elixir.Ecto.NoResultsError",
        message: "expected at least one result but got none in query",
        context: %{resource: "User", id: :rand.uniform(1000)}
      },
      %{
        type: "Elixir.Phoenix.Router.NoRouteError",
        message: "no route found for GET /api/nonexistent",
        context: %{path: "/api/nonexistent", method: "GET"}
      },
      %{
        type: "Elixir.DBConnection.ConnectionError",
        message: "connection not available and request was dropped from queue after timeout",
        context: %{pool_size: 10, timeout: 15000}
      },
      %{
        type: "Elixir.ArgumentError",
        message: "argument error: expected non-empty list",
        context: %{function: "process_batch", line: 42}
      },
      %{
        type: "Elixir.RuntimeError",
        message: "external API rate limit exceeded",
        context: %{api: "stripe", rate_limit: 100, retry_after: 60}
      },
      %{
        type: "Elixir.KeyError",
        message: "key :email not found in: %{name: \"John\", age: 30}",
        context: %{required_key: :email, available_keys: [:name, :age]}
      },
      %{
        type: "Elixir.FunctionClauseError",
        message: "no function clause matching in MyApp.Calculator.divide/2",
        context: %{args: [10, 0]}
      },
      %{
        type: "Elixir.Jason.DecodeError",
        message: "unexpected byte at position 15: 0x7D",
        context: %{input: "{\"invalid json", position: 15}
      }
    ]

    for _i <- 1..count do
      template = Enum.random(error_templates)

      # Create a transaction context
      ElixirTracer.OtherTransaction.start_transaction(
        "WebTransaction",
        "/api/#{random_endpoint()}"
      )

      # Add some transaction attributes
      ElixirTracer.Transaction.Reporter.add_attributes(%{
        user_id: :rand.uniform(1000),
        session_id: random_session_id(),
        request_id: random_request_id()
      })

      # Report the error
      exception = %RuntimeError{message: template.message}

      ElixirTracer.Error.Reporter.notice_error(
        exception,
        Map.merge(template.context, %{
          error_type_override: template.type,
          severity: Enum.random([:low, :medium, :high, :critical]),
          timestamp: System.system_time(:millisecond)
        })
      )

      ElixirTracer.OtherTransaction.stop_transaction()

      # Small delay to make timestamps different
      Process.sleep(10)
    end

    :ok
  end

  @doc """
  Generate realistic performance metrics.
  """
  def generate_metrics do
    # Database metrics
    database_operations = [
      {:datastore, "PostgreSQL", "users", "SELECT"},
      {:datastore, "PostgreSQL", "users", "INSERT"},
      {:datastore, "PostgreSQL", "users", "UPDATE"},
      {:datastore, "PostgreSQL", "orders", "SELECT"},
      {:datastore, "PostgreSQL", "orders", "INSERT"},
      {:datastore, "PostgreSQL", "products", "SELECT"},
      {:datastore, "PostgreSQL", "sessions", "SELECT"},
      {:datastore, "PostgreSQL", "sessions", "DELETE"}
    ]

    # Generate multiple calls to each operation
    for operation <- database_operations do
      call_count = :rand.uniform(50) + 10

      for _i <- 1..call_count do
        base_duration =
          case elem(operation, 3) do
            # 0-100ms
            "SELECT" -> :rand.uniform(100) / 1000.0
            # 0-50ms
            "INSERT" -> :rand.uniform(50) / 1000.0
            # 0-75ms
            "UPDATE" -> :rand.uniform(75) / 1000.0
            # 0-60ms
            "DELETE" -> :rand.uniform(60) / 1000.0
          end

        # Add occasional slow queries
        duration =
          if :rand.uniform(10) == 1 do
            # 10x slower occasionally
            base_duration * 10
          else
            base_duration
          end

        ElixirTracer.Metric.Reporter.report_metric(operation, duration_s: duration)
      end
    end

    # External service metrics
    external_services = [
      {:external, "api.stripe.com", "POST"},
      {:external, "api.stripe.com", "GET"},
      {:external, "api.sendgrid.com", "POST"},
      {:external, "s3.amazonaws.com", "PUT"},
      {:external, "api.github.com", "GET"}
    ]

    for service <- external_services do
      call_count = :rand.uniform(30) + 5

      for _i <- 1..call_count do
        # 0-500ms for external calls
        duration = :rand.uniform(500) / 1000.0
        ElixirTracer.Metric.Reporter.report_metric(service, duration_s: duration)
      end
    end

    # Custom metrics
    custom_metrics = [
      "Custom/Cache/Hits",
      "Custom/Cache/Misses",
      "Custom/Queue/JobsProcessed",
      "Custom/Email/Sent",
      "Custom/ImageProcessing/ResizeTime",
      "Custom/API/RateLimitRemaining"
    ]

    for metric <- custom_metrics do
      if String.ends_with?(metric, "Time") do
        # Duration-based metrics
        for _i <- 1..:rand.uniform(20) do
          ElixirTracer.Metric.Reporter.report_metric(metric,
            duration_s: :rand.uniform(2000) / 1000.0
          )
        end
      else
        # Counter metrics
        for _i <- 1..:rand.uniform(100) do
          ElixirTracer.Metric.Reporter.increment_metric(metric)
        end
      end
    end

    :ok
  end

  @doc """
  Generate realistic custom events (business events).
  """
  def generate_events(count \\ 10) do
    event_generators = [
      &user_signup_event/0,
      &purchase_completed_event/0,
      &feature_used_event/0,
      &subscription_changed_event/0,
      &payment_failed_event/0,
      &login_event/0,
      &export_generated_event/0,
      &api_key_created_event/0
    ]

    for _i <- 1..count do
      generator = Enum.random(event_generators)
      generator.()
      # Small delay for different timestamps
      Process.sleep(5)
    end

    :ok
  end

  # Event Generators

  defp user_signup_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("UserSignup", %{
      email: random_email(),
      plan: Enum.random(["free", "starter", "pro", "enterprise"]),
      source: Enum.random(["google_ads", "organic", "referral", "direct"]),
      campaign: Enum.random(["summer_sale", "product_hunt", "fb_ads", nil]),
      country: Enum.random(["US", "UK", "CA", "DE", "FR"]),
      device: Enum.random(["desktop", "mobile", "tablet"])
    })
  end

  defp purchase_completed_event do
    items_count = :rand.uniform(5)
    amount = (:rand.uniform(50000) / 100.0) |> Float.round(2)

    ElixirTracer.CustomEvent.Reporter.report_custom_event("PurchaseCompleted", %{
      order_id: "ord_#{random_id()}",
      amount: amount,
      currency: "USD",
      items_count: items_count,
      payment_method: Enum.random(["stripe", "paypal", "card"]),
      discount_applied: :rand.uniform(100) > 70,
      user_id: :rand.uniform(1000)
    })
  end

  defp feature_used_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("FeatureUsed", %{
      feature: Enum.random(["pdf_export", "csv_import", "api_access", "analytics", "webhooks"]),
      user_id: :rand.uniform(1000),
      duration_ms: :rand.uniform(5000),
      success: :rand.uniform(100) > 10,
      plan: Enum.random(["free", "pro", "enterprise"])
    })
  end

  defp subscription_changed_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("SubscriptionChanged", %{
      user_id: :rand.uniform(1000),
      from_plan: Enum.random(["free", "starter", "pro"]),
      to_plan: Enum.random(["starter", "pro", "enterprise"]),
      change_type: Enum.random(["upgrade", "downgrade"]),
      annual: :rand.uniform(100) > 50,
      mrr_change: (:rand.uniform(10000) / 100.0) |> Float.round(2)
    })
  end

  defp payment_failed_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("PaymentFailed", %{
      user_id: :rand.uniform(1000),
      amount: (:rand.uniform(10000) / 100.0) |> Float.round(2),
      currency: "USD",
      reason: Enum.random(["insufficient_funds", "card_declined", "expired_card", "invalid_cvv"]),
      retry_count: :rand.uniform(3),
      subscription_id: "sub_#{random_id()}"
    })
  end

  defp login_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("UserLogin", %{
      user_id: :rand.uniform(1000),
      method: Enum.random(["password", "google", "github", "saml"]),
      device: Enum.random(["desktop", "mobile", "tablet"]),
      location: Enum.random(["US", "UK", "CA", "DE", "FR"]),
      ip_address: random_ip(),
      success: :rand.uniform(100) > 5
    })
  end

  defp export_generated_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("ExportGenerated", %{
      user_id: :rand.uniform(1000),
      format: Enum.random(["csv", "xlsx", "pdf", "json"]),
      records_count: :rand.uniform(100_000),
      file_size_mb: (:rand.uniform(5000) / 100.0) |> Float.round(2),
      duration_seconds: (:rand.uniform(3000) / 100.0) |> Float.round(2)
    })
  end

  defp api_key_created_event do
    ElixirTracer.CustomEvent.Reporter.report_custom_event("ApiKeyCreated", %{
      user_id: :rand.uniform(1000),
      key_id: "key_#{random_id()}",
      scopes: Enum.random([["read"], ["read", "write"], ["read", "write", "delete"]]),
      environment: Enum.random(["production", "staging", "development"]),
      expires_at:
        DateTime.add(DateTime.utc_now(), :rand.uniform(365), :day) |> DateTime.to_iso8601()
    })
  end

  # Helper Functions

  defp random_endpoint do
    Enum.random([
      "users/index",
      "users/show",
      "orders/create",
      "products/list",
      "dashboard/analytics",
      "reports/generate",
      "settings/update",
      "api/v1/webhooks"
    ])
  end

  defp random_email do
    name = Enum.random(["alice", "bob", "charlie", "dana", "eve", "frank"])
    domain = Enum.random(["gmail.com", "yahoo.com", "company.com", "example.org"])
    "#{name}#{:rand.uniform(999)}@#{domain}"
  end

  defp random_session_id do
    "sess_#{random_id()}"
  end

  defp random_request_id do
    "req_#{random_id()}"
  end

  defp random_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp random_ip do
    "#{:rand.uniform(255)}.#{:rand.uniform(255)}.#{:rand.uniform(255)}.#{:rand.uniform(255)}"
  end
end
