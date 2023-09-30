defmodule PinpointWeb.RelationshipLive.Friends do
  alias Pinpoint.Locations
  alias Pinpoint.Accounts
  alias Pinpoint.Accounts.User
  use PinpointWeb, :live_view

  alias Pinpoint.Relationships
  alias Pinpoint.Relationships.{FriendshipInfoRepo, Relationship}
  alias PinpointWeb.RelationshipLive.OtherComponents

  defp get_dom_id(user_id), do: "user-#{user_id}"

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <OtherComponents.relationships_links current_view={:friends} />
      <:actions>
        <.link patch={~p"/relationships/new"}>
          <.button>Send Friend Request</.button>
        </.link>
      </:actions>
    </.header>

    <.table id="table_of_users" rows={@streams.friends_with_info}>
      <:col :let={{_id, %{user: user}}} label="Name"><%= user.name %></:col>
      <:col :let={{_id, %{user: user}}} label="Email"><%= user.email %></:col>
      <:action :let={{_, %{user: user, friendship_info: friendship_info}}}>
        <%= if friendship_info.share_location do %>
          <.link
            phx-click={
              JS.push("set_location_sharing_status",
                value: %{id: user.id, status: false}
              )
            }
            data-confirm="Are you sure?"
          >
            Stop sharing location
          </.link>
        <% else %>
          <.link
            phx-click={
              JS.push("set_location_sharing_status",
                value: %{id: user.id, status: true}
              )
            }
            data-confirm="Are you sure?"
          >
            Share location
          </.link>
        <% end %>
        <.link
          phx-click={JS.push("unfriend", value: %{id: user.id}) |> hide("##{user.id}")}
          data-confirm="Are you sure?"
        >
          Unfriend
        </.link>
        <.link
          phx-click={JS.push("block", value: %{id: user.id}) |> hide("##{user.id}")}
          data-confirm="Are you sure?"
        >
          Block
        </.link>
      </:action>
    </.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> stream_configure(:friends_with_info, dom_id: &get_dom_id(&1.user.id))
      |> stream(
        :friends_with_info,
        Relationships.Finders.ListFriendsWithInfo.find(current_user.id)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Friends")
    |> assign(:relationship, nil)
  end

  @impl true
  def handle_event(
        "set_location_sharing_status",
        %{"id" => other_user_id, "status" => status},
        socket
      )
      when is_integer(other_user_id) and is_boolean(status) do
    current_user = socket.assigns.current_user

    %Relationship{status: :friend, id: relationship_id} =
      Relationships.RelationshipRepo.get_relationship!(current_user.id, other_user_id)

    friendship_info = FriendshipInfoRepo.get_friendship_info!(relationship_id)

    {:ok, friendship_info} =
      FriendshipInfoRepo.update_friendship_info(friendship_info, %{share_location: status})

    Locations.update_sharing_status(current_user.id, other_user_id, status)

    {:noreply,
     stream_insert(
       socket,
       :friends_with_info,
       %{
         id: "user-#{other_user_id}",
         user: Accounts.get_user!(other_user_id),
         friendship_info: friendship_info
       },
       at: -1
     )}
  end

  @impl true
  def handle_event("unfriend", %{"id" => other_user_id}, socket) when is_integer(other_user_id) do
    Relationships.Services.DeleteNonBlockedRelationshipsBetweenTwoUsers.call(
      socket.assigns.current_user.id,
      other_user_id
    )

    {:noreply, stream_delete_by_dom_id(socket, :friends_with_info, get_dom_id(other_user_id))}
  end

  @impl true
  def handle_event("block", %{"id" => other_user_id}, socket) when is_integer(other_user_id) do
    other_user = %User{id: other_user_id}

    {:ok, _} = Relationships.Services.BlockUser.call(socket.assigns.current_user, other_user)

    {:noreply, stream_delete_by_dom_id(socket, :friends_with_info, get_dom_id(other_user_id))}
  end
end
