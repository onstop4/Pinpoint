defmodule PinpointWeb.RelationshipLive.ReceivedFriendRequests do
  alias Pinpoint.Accounts.User
  use PinpointWeb, :live_view

  alias Pinpoint.Relationships
  alias Pinpoint.Relationships.Relationship
  alias PinpointWeb.RelationshipLive.OtherComponents

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <OtherComponents.relationships_links current_view={:received} />

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
          Block
        </.link>
      </:action>
    </OtherComponents.user_table>

    <.modal
      :if={@live_action == :new}
      id="relationship-modal"
      show
      on_cancel={JS.patch(~p"/relationships/sent")}
    >
      <.live_component
        module={PinpointWeb.RelationshipLive.FormComponent}
        id={:new}
        title={@page_title}
        patch={~p"/relationships/sent"}
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
        Relationships.Finders.ListRelatedUsersWithStatus.find(current_user, :pending_friend,
          reverse: true
        )
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
  def handle_event("accept", %{"id" => other_user_id}, socket) when is_integer(other_user_id) do
    relationship =
      Relationships.RelationshipRepo.get_relationship!(
        other_user_id,
        socket.assigns.current_user.id
      )

    {:ok, _} = Relationships.Services.ConfirmFriendRequest.call(relationship)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end

  @impl true
  def handle_event("decline", %{"id" => other_user_id}, socket) when is_integer(other_user_id) do
    %Relationship{status: :pending_friend} =
      relationship =
      Relationships.RelationshipRepo.get_relationship!(
        other_user_id,
        socket.assigns.current_user.id
      )

    {:ok, _} = Relationships.RelationshipRepo.delete_relationship(relationship)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end

  @impl true
  def handle_event("block", %{"id" => other_user_id}, socket) when is_integer(other_user_id) do
    {:ok, _} =
      Relationships.Services.BlockUser.call(socket.assigns.current_user.id, other_user_id)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end
end
