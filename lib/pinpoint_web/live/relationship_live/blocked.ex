defmodule PinpointWeb.RelationshipLive.Blocked do
  alias Pinpoint.Accounts.User
  use PinpointWeb, :live_view

  alias Pinpoint.Relationships
  alias PinpointWeb.RelationshipLive.OtherComponents

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      <OtherComponents.relationships_links current_view={:blocked} />
    </.header>

    <OtherComponents.user_table users={@streams.other_users}>
      <:action :let={other_user_id}>
        <.link
          phx-click={JS.push("unblock", value: %{id: other_user_id}) |> hide("##{other_user_id}")}
          data-confirm="Are you sure?"
        >
          Unblock
        </.link>
      </:action>
    </OtherComponents.user_table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> stream(
        :other_users,
        Relationships.Finders.ListRelatedUsersWithStatus.find(current_user.id, :blocked)
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Blocked Users")
    |> assign(:relationship, nil)
  end

  @impl true
  def handle_event("unblock", %{"id" => other_user_id}, socket) do
    relationship =
      Relationships.RelationshipRepo.get_relationship!(
        socket.assigns.current_user.id,
        other_user_id
      )

    {:ok, _} = Relationships.RelationshipRepo.delete_relationship(relationship)

    {:noreply, stream_delete(socket, :other_users, %User{id: other_user_id})}
  end
end
