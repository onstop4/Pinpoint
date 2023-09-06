defmodule PinpointWeb.MapLive do
  alias Pinpoint.Locations
  alias Pinpoint.Locations.{Broadcasting, Subscribing}
  alias Pinpoint.Accounts
  use PinpointWeb, :live_view

  @safe_user_columns [:id, :name]

  defp modify_socket_because_sharing_started(socket, user_id, location) do
    cond do
      user_id == socket.assigns.current_user.id ->
        {:noreply, assign(socket, current_user_is_sharing: true)}

      socket.assigns.include_friends_locations and
          !Enum.find(socket.assigns.friends, fn user -> user.id == user_id end) ->
        user = user_id |> Accounts.get_user!() |> Map.take(@safe_user_columns)

        location =
          case location do
            {x, y} -> [x, y]
            _ -> nil
          end

        {:noreply,
         socket
         |> update(
           :friends,
           fn friends ->
             Enum.sort_by([user | friends], fn user -> user.name end)
           end
         )
         |> push_event("user_started_sharing", %{type: :friend, user: user, location: location})}

      true ->
        {:noreply, socket}
    end
  end

  defp modify_socket_because_sharing_stopped(socket, user_id) do
    cond do
      user_id == socket.assigns.current_user.id ->
        {:noreply,
         socket
         |> assign(current_user_is_sharing: false)
         |> push_event("user_stopped_sharing", %{type: :current_user})}

      socket.assigns.include_friends_locations ->
        {:noreply,
         socket
         |> update(:friends, fn friends ->
           Enum.reject(friends, fn user -> user.id == user_id end)
         end)
         |> push_event("user_stopped_sharing", %{type: :friend, user_id: user_id})}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="map-container"
      phx-hook="MapHook"
      class="flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-center flex-col"
    >
      <div>
        <%= if @sharing_location do %>
          <.button phx-click="stop_sharing_location">Stop sharing location</.button>
        <% else %>
          <.button phx-click="start_sharing_location">Start sharing location</.button>
        <% end %>

        <%= if @include_friends_locations do %>
          <.button phx-click="exclude_friends_locations">Exclude locations of friends</.button>
        <% else %>
          <.button phx-click="include_friends_locations">Include locations of friends</.button>
        <% end %>

        <.button :if={@tracking} phx-click="stop_tracking">Stop tracking</.button>
      </div>

      <div id="actual-map" phx-update="ignore"></div>

      <%= if @current_user_is_sharing do %>
        <.button phx-click={JS.push("track_current_user")}>Track current location</.button>
      <% end %>

      <%= if @friends != [] do %>
        <div>View a friend's location:</div>

        <ul :for={friend <- @friends} class="list-disc list-inside">
          <li phx-click={JS.push("track_user", value: %{user_id: friend.id})}><%= friend.name %></li>
        </ul>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user_id = socket.assigns.current_user.id

    socket =
      if connected?(socket) do
        Subscribing.subscribe(current_user_id)

        case Locations.get_value_from_cache(current_user_id) do
          {_, {x, y}} ->
            socket
            |> assign(:current_user_is_sharing, true)
            |> push_event("user_new_location", %{
              type: :current_user,
              location: [x, y]
            })

          _ ->
            assign(socket, :current_user_is_sharing, false)
        end
      else
        assign(socket, :current_user_is_sharing, false)
      end

    {:ok,
     assign(socket,
       page_title: "Map",
       dont_show_map_button: true,
       sharing_location: false,
       include_friends_locations: false,
       friends: [],
       tracking: nil
     )}
  end

  @impl true
  def handle_event("start_sharing_location", _, socket) do
    if not socket.assigns.sharing_location do
      Broadcasting.start_sharing_location(socket.assigns.current_user.id)

      {:noreply,
       socket
       |> assign(sharing_location: true)
       |> push_event("youve_started_sharing", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("stop_sharing_location", _, socket) do
    Broadcasting.stop_sharing_location(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(sharing_location: false)
     |> push_event("youve_stopped_sharing", %{})}
  end

  @impl true
  def handle_event("new_location", [x, y], socket)
      when is_number(x) and is_number(y) do
    if socket.assigns.sharing_location do
      Broadcasting.share_new_location(
        socket.assigns.current_user.id,
        {x, y}
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("include_friends_locations", _, socket) do
    friends_and_locations =
      Subscribing.subscribe_to_friends(
        socket.assigns.current_user.id,
        @safe_user_columns,
        fn
          user, {x, y} -> %{user: user, location: [x, y]}
          user, nil -> %{user: user}
        end
      )

    friends =
      Enum.map(friends_and_locations, fn friend_and_location -> friend_and_location.user end)

    {:noreply,
     socket
     |> assign(
       include_friends_locations: true,
       friends: friends
     )
     |> push_event("update_friends_list", %{friends_and_locations: friends_and_locations})}
  end

  @impl true
  def handle_event("exclude_friends_locations", _, socket) do
    Subscribing.unsubscribe_from_friends(socket.assigns.friends)

    {:noreply,
     socket
     |> assign(include_friends_locations: false, friends: [])
     |> push_event("update_friends_list", %{friends_and_locations: []})}
  end

  @impl true
  def handle_event("track_current_user", _, socket) do
    {:noreply,
     socket
     |> assign(tracking: :current_user)
     |> push_event("track_user", %{type: :current_user})}
  end

  @impl true
  def handle_event("track_user", %{"user_id" => user_id}, socket) when is_integer(user_id) do
    {:noreply,
     socket
     |> assign(tracking: user_id)
     |> push_event("track_user", %{type: :friend, user_id: user_id})}
  end

  @impl true
  def handle_event("stop_tracking", _, socket) do
    {:noreply, socket |> assign(tracking: nil) |> push_event("stop_tracking", %{})}
  end

  @impl true
  def handle_info({:started_sharing, user_id, location}, socket) do
    modify_socket_because_sharing_started(socket, user_id, location)
  end

  @impl true
  def handle_info({:stopped_sharing, user_id}, socket) do
    modify_socket_because_sharing_stopped(socket, user_id)
  end

  @impl true
  def handle_info({:new_location, user_id, {x, y}}, socket) do
    location = [x, y]

    if user_id == socket.assigns.current_user.id do
      {:noreply,
       push_event(socket, "user_new_location", %{type: :current_user, location: location})}
    else
      {:noreply,
       push_event(socket, "user_new_location", %{
         type: :friend,
         user_id: user_id,
         location: location
       })}
    end
  end

  @impl true
  def handle_info(:sharing_from_alternate_location, socket) do
    {:noreply,
     socket
     |> assign(sharing_location: false)
     |> push_event("youve_stopped_sharing", %{})
     |> put_flash(:error, "You started sharing your location from another device.")}
  end

  @impl true
  def handle_info({:updated_sharing_status, user_id, true}, socket) do
    if socket.assigns.include_friends_locations do
      Subscribing.subscribe(user_id)

      case Locations.get_value_from_cache(user_id) do
        {_, location} ->
          modify_socket_because_sharing_started(socket, user_id, location)

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:updated_sharing_status, user_id, false}, socket) do
    if socket.assigns.include_friends_locations do
      Subscribing.unsubscribe(user_id)
      modify_socket_because_sharing_stopped(socket, user_id)
    else
      {:noreply, socket}
    end
  end
end
