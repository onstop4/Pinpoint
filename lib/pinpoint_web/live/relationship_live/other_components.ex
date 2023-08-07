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
end
