defmodule ElixirDashboardWeb.Repo.Migrations.CreateDemoTables do
  use Ecto.Migration

  def change do
    create table(:demo_users) do
      add(:name, :string)
      add(:email, :string)
      add(:age, :integer)

      timestamps()
    end

    create table(:demo_posts) do
      add(:title, :string)
      add(:body, :text)
      add(:user_id, references(:demo_users, on_delete: :delete_all))

      timestamps()
    end

    create(index(:demo_posts, [:user_id]))

    # Seed some data for testing
    execute("""
    INSERT INTO demo_users (name, email, age, inserted_at, updated_at)
    SELECT
      'User ' || generate_series,
      'user' || generate_series || '@example.com',
      20 + (generate_series % 50),
      NOW(),
      NOW()
    FROM generate_series(1, 1000);
    """)

    execute("""
    INSERT INTO demo_posts (title, body, user_id, inserted_at, updated_at)
    SELECT
      'Post ' || generate_series,
      'This is the body of post ' || generate_series || '. ' || repeat('Lorem ipsum dolor sit amet. ', 10),
      1 + (generate_series % 1000),
      NOW(),
      NOW()
    FROM generate_series(1, 5000);
    """)
  end
end
