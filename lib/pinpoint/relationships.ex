defmodule Pinpoint.Relationships do
  @moduledoc """
  The Relationships context.
  """

  import Ecto.Query, warn: false
  alias Pinpoint.Accounts.User
  alias Pinpoint.Repo

  alias Pinpoint.Relationships.Relationship

  def list_relationships() do
    Repo.all(Relationship)
  end

  def list_relationships_of_user_with_status(user, status) do
    user
    |> generate_query_for_relationship(status)
    |> Repo.all()
  end

  def list_friends_of_user_with_info(user) do
    user
    |> generate_query_for_relationship(:friends)
    |> preload([:friendship_info])
    |> Repo.all()
  end

  defp generate_query_for_relationship(user_from, status) do
    from(relationship in Relationship,
      where: relationship.from_id == ^user_from.id and relationship.status == ^status,
      join: user_to in User,
      on: user_to.id == relationship.to_id,
      select: user_to
    )
  end

  @doc """
  Gets a single relationship.

  Raises if the Relationship does not exist.

  ## Examples

      iex> get_relationship!(123)
      %Relationship{}

  """
  def get_relationship!(id), do: Repo.get!(Relationship, id)

  def get_relationship!(user_from_id, user_to_id)
      when is_integer(user_from_id) and is_integer(user_to_id),
      do: Repo.get_by!(Relationship, [from_id: user_from_id, to_id: user_to_id], [])

  def get_relationship!(%User{id: user_from_id}, %User{id: user_to_id}),
    do: get_relationship!(user_from_id, user_to_id)

  @doc """
  Creates a relationship.

  ## Examples

      iex> create_relationship(%{field: value})
      {:ok, %Relationship{}}

      iex> create_relationship(%{field: bad_value})
      {:error, ...}

  """
  def create_relationship(attrs \\ %{}) do
    %Relationship{}
    |> Relationship.changeset(attrs)
    |> Repo.insert()
  end

  def create_friend_request(%User{id: from_user_id}, %User{id: to_user_id}) do
    create_relationship(%{from_id: from_user_id, to_id: to_user_id, status: :pending_friend})
  end

  def confirm_friend_request(
        %Relationship{from_id: from_user_id, to_id: to_user_id} = relationship
      ) do
    Repo.transaction(fn ->
      with {:ok, from_to_relationship} <- update_relationship(relationship, %{status: :friend}),
           {:ok, to_from_relationship} <-
             create_relationship(%{from_id: to_user_id, to_id: from_user_id, status: :friend}),
           {:ok, _} <- create_friendship_info(%{relationship_id: from_to_relationship}) do
        {:ok, from_to_relationship, to_from_relationship}
      end
    end)
  end

  @doc """
  Updates a relationship.

  ## Examples

      iex> update_relationship(relationship, %{field: new_value})
      {:ok, %Relationship{}}

      iex> update_relationship(relationship, %{field: bad_value})
      {:error, ...}

  """
  def update_relationship(%Relationship{} = relationship, attrs) do
    relationship
    |> Relationship.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Relationship.

  ## Examples

      iex> delete_relationship(relationship)
      {:ok, %Relationship{}}

      iex> delete_relationship(relationship)
      {:error, ...}

  """
  def delete_relationship(%Relationship{} = relationship) do
    Repo.delete(relationship)
  end

  @doc """
  Returns a data structure for tracking relationship changes.

  ## Examples

      iex> change_relationship(relationship)
      %Todo{...}

  """
  def change_relationship(%Relationship{} = relationship, attrs \\ %{}) do
    Relationship.changeset(relationship, attrs)
  end

  alias Pinpoint.Relationships.FriendshipInfo

  @doc """
  Returns the list of friendship_info.

  ## Examples

      iex> list_friendship_info()
      [%FriendshipInfo{}, ...]

  """
  def list_friendship_info do
    Repo.all(FriendshipInfo)
  end

  @doc """
  Gets a single friendship_info.

  Raises if the Friendship info does not exist.

  ## Examples

      iex> get_friendship_info!(123)
      %FriendshipInfo{}

  """
  def get_friendship_info!(id), do: Repo.get!(FriendshipInfo, id)

  @doc """
  Creates a friendship_info.

  ## Examples

      iex> create_friendship_info(%{field: value})
      {:ok, %FriendshipInfo{}}

      iex> create_friendship_info(%{field: bad_value})
      {:error, ...}

  """
  def create_friendship_info(attrs \\ %{}) do
    %FriendshipInfo{}
    |> FriendshipInfo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a friendship_info.

  ## Examples

      iex> update_friendship_info(friendship_info, %{field: new_value})
      {:ok, %FriendshipInfo{}}

      iex> update_friendship_info(friendship_info, %{field: bad_value})
      {:error, ...}

  """
  def update_friendship_info(%FriendshipInfo{} = friendship_info, attrs) do
    friendship_info
    |> FriendshipInfo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a FriendshipInfo.

  ## Examples

      iex> delete_friendship_info(friendship_info)
      {:ok, %FriendshipInfo{}}

      iex> delete_friendship_info(friendship_info)
      {:error, ...}

  """
  def delete_friendship_info(%FriendshipInfo{} = friendship_info) do
    Repo.delete(friendship_info)
  end

  @doc """
  Returns a data structure for tracking friendship_info changes.

  ## Examples

      iex> change_friendship_info(friendship_info)
      %Todo{...}

  """
  def change_friendship_info(%FriendshipInfo{} = friendship_info, attrs \\ %{}) do
    FriendshipInfo.changeset(friendship_info, attrs)
  end
end
