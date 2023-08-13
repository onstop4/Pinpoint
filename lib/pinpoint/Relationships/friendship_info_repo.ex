defmodule Pinpoint.Relationships.FriendshipInfoRepo do
  alias Pinpoint.Repo
  alias Pinpoint.Relationships.FriendshipInfo

  def list_friendship_info do
    Repo.all(FriendshipInfo)
  end

  def get_friendship_info!(id), do: Repo.get!(FriendshipInfo, id)

  def create_friendship_info(attrs \\ %{}) do
    %FriendshipInfo{}
    |> FriendshipInfo.changeset(attrs)
    |> Repo.insert()
  end

  def update_friendship_info(%FriendshipInfo{} = friendship_info, attrs) do
    friendship_info
    |> FriendshipInfo.changeset(attrs)
    |> Repo.update()
  end

  def delete_friendship_info(%FriendshipInfo{} = friendship_info) do
    Repo.delete(friendship_info)
  end

  def change_friendship_info(%FriendshipInfo{} = friendship_info, attrs \\ %{}) do
    FriendshipInfo.changeset(friendship_info, attrs)
  end
end
