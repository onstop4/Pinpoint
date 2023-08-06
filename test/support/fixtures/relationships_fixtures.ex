defmodule Pinpoint.RelationshipsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pinpoint.Relationships` context.
  """
  alias Pinpoint.Accounts
  alias Pinpoint.Accounts.User

  @doc """
  Generate a relationship.
  """
  def relationship_fixture(attrs \\ %{}) do
    {:ok, %User{id: from_user_id}} =
      Accounts.register_user(%{
        name: "User1",
        email: "user1@example.com",
        password: "123456789012"
      })

    {:ok, %User{id: to_user_id}} =
      Accounts.register_user(%{
        name: "User2",
        email: "user2@example.com",
        password: "123456789012"
      })

    {:ok, relationship} =
      attrs
      |> Enum.into(%{
        from_id: from_user_id,
        to_id: to_user_id,
        status: :friend
      })
      |> Pinpoint.Relationships.create_relationship()

    relationship
  end

  @doc """
  Generate a friendship_info.
  """
  def friendship_info_fixture(attrs \\ %{}) do
    {:ok, %User{id: from_user_id}} =
      Accounts.register_user(%{
        name: "User1",
        email: "user1@example.com",
        password: "123456789012"
      })

    {:ok, %User{id: to_user_id}} =
      Accounts.register_user(%{
        name: "User2",
        email: "user2@example.com",
        password: "123456789012"
      })

    {:ok, relationship} =
      attrs
      |> Enum.into(%{
        from_id: from_user_id,
        to_id: to_user_id,
        status: :friend
      })
      |> Pinpoint.Relationships.create_relationship()

    {:ok, friendship_info} =
      attrs
      |> Enum.into(%{
        relationship_id: relationship.id,
        share_location: true
      })
      |> Pinpoint.Relationships.create_friendship_info()

    friendship_info
  end
end
