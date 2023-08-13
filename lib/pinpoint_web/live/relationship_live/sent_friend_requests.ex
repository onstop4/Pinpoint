defmodule PinpointWeb.RelationshipLive.SentFriendRequests do
  alias Pinpoint.Accounts.User
  use PinpointWeb, :live_view

  alias Pinpoint.Relationships
  alias PinpointWeb.RelationshipLive.OtherComponents

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Friend Requests Sent Out
      <:actions>
        <.link patch={~p"/relationships/new"}>
          <.button>Send Friend Request</.button>
        </.link>
      </:actions>
    </.header>

    <OtherComponents.user_table users={@streams.other_users}>
      <:action :let={other_user_id}>
        <.link
          phx-click={JS.push("delete", value: %{id: other_user_id}) |> hide("##{other_user_id}")}
          data-confirm="Are you sure?"
        >
          Delete
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
        Relationships.Finders.ListRelatedUsersWithStatus.find(current_user.id, :pending_friend)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Friend Requests Sent Out")
    |> assign(:relationship, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Friend Request")
    |> assign(:relationship, nil)
  end

  @impl true
  def handle_info(
        {PinpointWeb.RelationshipLive.FormComponent, {:new_friend_request, other_user}},
        socket
      ) do
    {:noreply, stream_insert(socket, :other_users, other_user)}
  end

  @impl true
  def handle_event("delete", %{"id" => other_user_id}, socket) do
    {:ok, _} =
      Relationships.Services.BlockUser.call(socket.assigns.current_user.id, other_user_id)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end
end
