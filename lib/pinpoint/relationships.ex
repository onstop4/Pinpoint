defmodule Pinpoint.Relationships do
  @moduledoc """
  The Relationships context.
  """

  import Ecto.Query, warn: false
  alias Pinpoint.Relationships.FriendshipInfo
  alias Pinpoint.Accounts.User
  alias Pinpoint.Repo

  alias Pinpoint.Relationships.Relationship

  def list_relationships() do
    Repo.all(Relationship)
  end

  def list_relationships_of_user_with_status(user_from, status) do
    from(relationship in Relationship,
      where: relationship.from_id == ^user_from.id and relationship.status == ^status,
      join: user_to in User,
      on: user_to.id == relationship.to_id,
      select: user_to
    )
    |> Repo.all()
  end

  def list_relationships_to_user_with_status(user_to, status) do
    from(relationship in Relationship,
      where: relationship.to_id == ^user_to.id and relationship.status == ^status,
      join: user_from in User,
      on: user_from.id == relationship.from_id,
      select: user_from
    )
    |> Repo.all()
  end

  def list_friends_with_info(user_from) do
    from(relationship in Relationship,
      where: relationship.from_id == ^user_from.id and relationship.status == :friend,
      join: user_to in User,
      on: user_to.id == relationship.to_id,
      join: friendship_info in FriendshipInfo,
      on: relationship.id == friendship_info.relationship_id,
      select: %{user: user_to, friendship_info: friendship_info}
    )
    |> Repo.all()
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

  def confirm_friend_request(
        %Relationship{from_id: from_user_id, to_id: to_user_id} = relationship
      ) do
    Repo.transaction(fn ->
      with {:ok, to_from_relationship} <-
             create_relationship(%{from_id: to_user_id, to_id: from_user_id, status: :friend}),
           {:ok, from_to_relationship} <- update_relationship(relationship, %{status: :friend}),
           {:ok, _} <- create_friendship_info(%{relationship_id: from_to_relationship.id}),
           {:ok, _} <- create_friendship_info(%{relationship_id: to_from_relationship.id}) do
        {:ok, {from_to_relationship, to_from_relationship}}
      end
    end)
  end

  def create_friend_request(%User{id: from_user_id}, %User{id: to_user_id}) do
    create_friend_request(from_user_id, to_user_id)
  end

  def create_friend_request(from_user_id, to_user_id)
      when is_integer(from_user_id) and is_integer(to_user_id) do
    create_relationship(%{from_id: from_user_id, to_id: to_user_id, status: :pending_friend})
  end

  def delete_all_relationships(from_user_id, to_user_id)
      when is_integer(from_user_id) and is_integer(to_user_id) do
    Repo.delete_all(
      from(relationship in Relationship,
        where:
          (relationship.from_id == ^from_user_id and relationship.to_id == ^to_user_id) or
            (relationship.from_id == ^to_user_id and relationship.to_id == ^from_user_id)
      )
    )

    :ok
  end

  def delete_all_relationships(%User{id: from_user_id}, %User{id: to_user_id}) do
    from_to_relationship = get_relationship!(from_user_id, to_user_id)
    to_from_relationship = get_relationship!(to_user_id, from_user_id)

    Repo.transaction(fn ->
      {:ok, _} =
        delete_relationship(from_to_relationship)

      {:ok, _} =
        delete_relationship(to_from_relationship)
    end)

    :ok
  end

  def delete_all_relationships(%Relationship{from_id: from_user_id, to_id: to_user_id}) do
    delete_all_relationships(from_user_id, to_user_id)
  end

  def block_user(from_user_id, to_user_id)
      when is_integer(from_user_id) and is_integer(to_user_id) do
    Repo.transaction(fn ->
      delete_all_relationships(from_user_id, to_user_id)

      {:ok, from_to_relationship} =
        create_relationship(%{from_id: from_user_id, to_id: to_user_id, status: :blocked})

      from_to_relationship
    end)
  end

  def block_user(%User{id: from_user_id}, %User{id: to_user_id}) do
    block_user(from_user_id, to_user_id)
  end

  def block_user(%Relationship{from_id: from_user_id, to_id: to_user_id}) do
    block_user(from_user_id, to_user_id)
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
