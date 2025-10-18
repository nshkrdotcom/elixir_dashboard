[
  # Mix.Task callbacks - Mix doesn't ship with dialyzer specs by default
  ~r/callback_info_missing.*Mix\.Task/,
  # Erlang :inets and :httpc modules don't have complete type specs
  ~r/unknown_function.*:inets\.start\/0/,
  ~r/unknown_function.*:httpc\.request\/4/
]
