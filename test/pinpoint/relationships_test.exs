defmodule Pinpoint.RelationshipsTest do
  use Pinpoint.DataCase

  alias Pinpoint.Accounts
  alias Pinpoint.Accounts.User
  alias Pinpoint.Relationships

  describe "relationships" do
    alias Pinpoint.Relationships.Relationship

    import Pinpoint.RelationshipsFixtures

    @invalid_attrs %{status: nil}

    test "list_relationships/0 returns all relationships" do
      relationship = relationship_fixture()
      assert Relationships.list_relationships() == [relationship]
    end

    test "get_relationship!/1 returns the relationship with given id" do
      relationship = relationship_fixture()
      assert Relationships.get_relationship!(relationship.id) == relationship
    end

    test "create_relationship/1 with valid data creates a relationship" do
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

      valid_attrs = %{from_id: from_user_id, to_id: to_user_id, status: :friend}

      assert {:ok, %Relationship{} = relationship} =
               Relationships.create_relationship(valid_attrs)

      assert relationship.status == :friend
    end

    test "create_relationship/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Relationships.create_relationship(@invalid_attrs)
    end

    test "update_relationship/2 with valid data updates the relationship" do
      relationship = relationship_fixture()
      update_attrs = %{status: :pending_friend}

      assert {:ok, %Relationship{} = relationship} =
               Relationships.update_relationship(relationship, update_attrs)

      assert relationship.status == :pending_friend
    end

    test "update_relationship/2 with invalid data returns error changeset" do
      relationship = relationship_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Relationships.update_relationship(relationship, @invalid_attrs)

      assert relationship == Relationships.get_relationship!(relationship.id)
    end

    test "delete_relationship/1 deletes the relationship" do
      relationship = relationship_fixture()
      assert {:ok, %Relationship{}} = Relationships.delete_relationship(relationship)
      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(relationship.id) end
    end

    test "change_relationship/1 returns a relationship changeset" do
      relationship = relationship_fixture()
      assert %Ecto.Changeset{} = Relationships.change_relationship(relationship)
    end
  end

  describe "friendship_info" do
    alias Pinpoint.Relationships.FriendshipInfo

    import Pinpoint.RelationshipsFixtures

    @invalid_attrs %{share_location: nil}

    test "list_friendship_info/0 returns all friendship_info" do
      friendship_info = friendship_info_fixture()
      assert Relationships.list_friendship_info() == [friendship_info]
    end

    test "get_friendship_info!/1 returns the friendship_info with given id" do
      friendship_info = friendship_info_fixture()

      assert Relationships.get_friendship_info!(friendship_info.relationship_id) ==
               friendship_info
    end

    test "create_friendship_info/1 with valid data creates a friendship_info" do
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
        %{
          from_id: from_user_id,
          to_id: to_user_id,
          status: :friend
        }
        |> Pinpoint.Relationships.create_relationship()

      valid_attrs = %{
        relationship_id: relationship.id,
        share_location: true
      }

      assert {:ok, %FriendshipInfo{} = friendship_info} =
               Relationships.create_friendship_info(valid_attrs)

      assert friendship_info.share_location == true
    end

    test "create_friendship_info/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Relationships.create_friendship_info(@invalid_attrs)
    end

    test "update_friendship_info/2 with valid data updates the friendship_info" do
      friendship_info = friendship_info_fixture()
      update_attrs = %{share_location: false}

      assert {:ok, %FriendshipInfo{} = friendship_info} =
               Relationships.update_friendship_info(friendship_info, update_attrs)

      assert friendship_info.share_location == false
    end

    test "update_friendship_info/2 with invalid data returns error changeset" do
      friendship_info = friendship_info_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Relationships.update_friendship_info(friendship_info, @invalid_attrs)

      assert friendship_info ==
               Relationships.get_friendship_info!(friendship_info.relationship_id)
    end

    test "delete_friendship_info/1 deletes the friendship_info" do
      friendship_info = friendship_info_fixture()
      assert {:ok, %FriendshipInfo{}} = Relationships.delete_friendship_info(friendship_info)

      assert_raise Ecto.NoResultsError, fn ->
        Relationships.get_friendship_info!(friendship_info.relationship_id)
      end
    end

    test "change_friendship_info/1 returns a friendship_info changeset" do
      friendship_info = friendship_info_fixture()
      assert %Ecto.Changeset{} = Relationships.change_friendship_info(friendship_info)
    end
  end
end
