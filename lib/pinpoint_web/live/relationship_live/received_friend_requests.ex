defmodule PinpointWeb.RelationshipLive.ReceivedFriendRequests do
  alias Pinpoint.Accounts.User
  use PinpointWeb, :live_view

  alias Pinpoint.Relationships
  alias PinpointWeb.RelationshipLive.OtherComponents

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Friend Requests You Received
      <:actions>
        <.link patch={~p"/relationships/new"}>
          <.button>Send Friend Request</.button>
        </.link>
      </:actions>
    </.header>

    <OtherComponents.user_table users={@streams.other_users}>
      <:action :let={other_user_id}>
        <.link
          phx-click={JS.push("accept", value: %{id: other_user_id}) |> hide("##{other_user_id}")}
          data-confirm="Are you sure?"
        >
          Accept
        </.link>
        <.link
          phx-click={JS.push("decline", value: %{id: other_user_id}) |> hide("##{other_user_id}")}
          data-confirm="Are you sure?"
        >
          Decline
        </.link>
      </:action>
      <:action :let={other_user_id}>
        <.link
          phx-click={JS.push("block", value: %{id: other_user_id}) |> hide("##{other_user_id}")}
          data-confirm="Are you sure?"
        >
          block
        </.link>
      </:action>
    </OtherComponents.user_table>

    <.modal
      :if={@live_action == :new}
      id="relationship-modal"
      show
      on_cancel={JS.patch(~p"/relationships/pending")}
    >
      <.live_component
        module={PinpointWeb.RelationshipLive.FormComponent}
        id={:new}
        title={@page_title}
        patch={~p"/relationships/pending"}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> stream(
        :other_users,
        Relationships.list_relationships_to_user_with_status(current_user, :pending_friend)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Friend Requests You Received")
    |> assign(:relationship, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Friend Request")
    |> assign(:relationship, nil)
  end

  @impl true
  def handle_event("accept", %{"id" => other_user_id}, socket) do
    relationship =
      Relationships.get_relationship!(other_user_id, socket.assigns.current_user.id)

    {:ok, _} = Relationships.confirm_friend_request(relationship)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end

  @impl true
  def handle_event("decline", %{"id" => other_user_id}, socket) do
    relationship =
      Relationships.get_relationship!(other_user_id, socket.assigns.current_user.id)

    {:ok, _} = Relationships.delete_relationship(relationship)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end

  @impl true
  def handle_event("block", %{"id" => recipient_user_id}, socket) do
    recipient_user = %User{id: recipient_user_id}

    {:ok, _} = Relationships.block_user(socket.assigns.current_user, recipient_user)

    {:noreply, stream_delete(socket, :other_users, recipient_user)}
  end
end
