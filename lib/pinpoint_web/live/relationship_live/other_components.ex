defmodule PinpointWeb.RelationshipLive.OtherComponents do
  use PinpointWeb, :html

  attr :users, :any, required: true
  slot :action

  def user_table(assigns) do
    ~H"""
    <.table id="table_of_users" rows={@users}>
      <:col :let={{_id, user}} label="Name"><%= user.name %></:col>
      <:col :let={{_id, user}} label="Email"><%= user.email %></:col>
      <:action :let={{_, %{id: user_id}}}>
        <%= render_slot(@action, user_id) %>
      </:action>
    </.table>
    """
  end

  defp relationship_list_link(assigns) do
    ~H"""
    <li>
      <.link
        patch={@href}
        class={
          if @current,
            do: "border-b-2 border-sky-500",
            else: "hover:border-b-2 hover:border-sky-300"
        }
      >
        <%= render_slot(@inner_block) %>
      </.link>
    </li>
    """
  end

  def relationships_links(assigns) do
    ~H"""
    <ul class="flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-center">
      <.relationship_list_link href={~p"/relationships/friends"} current={@current_view == :friends}>
        Friends
      </.relationship_list_link>
      <.relationship_list_link href={~p"/relationships/sent"} current={@current_view == :sent}>
        Sent Requests
      </.relationship_list_link>
      <.relationship_list_link href={~p"/relationships/received"} current={@current_view == :received}>
        Received Requests
      </.relationship_list_link>
      <.relationship_list_link href={~p"/relationships/blocked"} current={@current_view == :blocked}>
        Blocked
      </.relationship_list_link>
    </ul>
    """
  end
end
