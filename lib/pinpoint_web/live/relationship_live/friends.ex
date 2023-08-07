defmodule PinpointWeb.RelationshipLive.Friends do
  alias Pinpoint.Accounts.User
  use PinpointWeb, :live_view

  alias Pinpoint.Relationships

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Friends
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
                value: %{info_id: friendship_info.relationship_id, status: false}
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
                value: %{info_id: friendship_info.relationship_id, status: true}
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
      |> stream_configure(:friends_with_info, dom_id: &"user-#{&1.user.id}")
      |> stream(
        :friends_with_info,
        Relationships.list_friends_with_info(current_user)
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
        %{"info_id" => friendship_info_id, "status" => status},
        socket
      ) do
    Relationships.get_friendship_info!(friendship_info_id)
    |> Relationships.update_friendship_info(%{share_location: status})
    |> IO.inspect()

    current_user = socket.assigns.current_user

    {:noreply,
     stream(
       socket,
       :friends_with_info,
       Relationships.list_friends_with_info(current_user) |> IO.inspect()
     )}
  end

  @impl true
  def handle_event("unfriend", %{"id" => recipient_user_id}, socket) do
    recipient_user = %User{id: recipient_user_id}

    relationship = Relationships.get_relationship!(socket.assigns.current_user, recipient_user_id)

    :ok = Relationships.delete_relationship(relationship)

    {:noreply, stream_delete(socket, :other_users, recipient_user)}
  end

  @impl true
  def handle_event("block", %{"id" => recipient_user_id}, socket) do
    recipient_user = %User{id: recipient_user_id}

    {:ok, _} = Relationships.block_user(socket.assigns.current_user, recipient_user)

    {:noreply, stream_delete(socket, :other_users, recipient_user)}
  end
end
