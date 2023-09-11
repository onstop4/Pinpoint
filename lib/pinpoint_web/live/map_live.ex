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

  defp toggle_friends_list(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#friends-list")
    # The two steps below were adapted from
    # https://github.com/phoenixframework/phoenix_live_view/pull/1721#issuecomment-1083130244.
    |> JS.remove_class("rotate-90", to: "#toggle-friends-list-caret")
    |> JS.add_class("rotate-90", to: "#toggle-friends-list-caret:not(.rotate-90)")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full relative">
      <div class="h-full w-auto" phx-update="ignore" id="map-container">
        <div id="map" class="h-full w-auto z-0" phx-hook="MapHook" />
      </div>

      <button
        phx-click={JS.show(to: "#map-overlay")}
        type="button"
        class="absolute top-2 left-2 items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="40"
          height="40"
          fill="currentColor"
          class="bi bi-list"
          viewBox="0 0 16 16"
        >
          <path
            fill-rule="evenodd"
            d="M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5z"
          />
        </svg>
      </button>

      <div
        id="map-overlay"
        aria-labelledby="slide-over-title"
        role="dialog"
        aria-modal="true"
        style="display: none"
      >
        <div class="absolute inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />

        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 left-0 flex max-w-full">
            <div class="pointer-events-auto relative w-screen md:max-w-md">
              <div class="flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl">
                <div>
                  <button phx-click={JS.hide(to: "#map-overlay")} class="float-right mt-8 pr-4">
                    <svg
                      class="h-6 w-6"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                  <div>
                    <%= if @sharing_location do %>
                      <button phx-click="stop_sharing_location" class="font-semibold text-gray-900">
                        Stop sharing <span class="absolute inset-0"></span>
                      </button>
                    <% else %>
                      <button phx-click="start_sharing_location" class="font-semibold text-gray-900">
                        Start sharing <span class="absolute inset-0"></span>
                      </button>
                    <% end %>
                  </div>
                </div>

                <%= if not is_nil(@tracking) do %>
                  <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                    <div>
                      <button phx-click="stop_tracking" class="font-semibold text-gray-900">
                        Stop tracking <span class="absolute inset-0"></span>
                      </button>
                    </div>
                  </div>
                <% else %>
                  <%= if @current_user_is_sharing do %>
                    <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                      <div>
                        <button phx-click="track_current_user" class="font-semibold text-gray-900">
                          Track your location <span class="absolute inset-0"></span>
                        </button>
                      </div>
                    </div>
                  <% end %>
                <% end %>

                <%= if @include_friends_locations do %>
                  <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                    <div>
                      <button
                        phx-click="exclude_friends_locations"
                        class="font-semibold text-gray-900"
                      >
                        Exclude friends <span class="absolute inset-0"></span>
                      </button>
                    </div>
                  </div>

                  <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                    <div>
                      <button phx-click={toggle_friends_list()} class="font-semibold text-gray-900">
                        Toggle friends list
                        <span class="inset-0 inline-block">
                          <svg
                            id="toggle-friends-list-caret"
                            xmlns="http://www.w3.org/2000/svg"
                            width="16"
                            height="16"
                            fill="currentColor"
                            class="bi bi-caret-right-fill"
                            viewBox="0 0 16 16"
                          >
                            <path d="m12.14 8.753-5.482 4.796c-.646.566-1.658.106-1.658-.753V3.204a1 1 0 0 1 1.659-.753l5.48 4.796a1 1 0 0 1 0 1.506z" />
                          </svg>
                        </span>
                      </button>
                    </div>
                  </div>
                  <div id="friends-list" class="px-6" style="display: none">
                    <%= if @friends != [] do %>
                      <ul :for={friend <- @friends}>
                        <li class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                          <button phx-click={JS.push("track_user", value: %{user_id: friend.id})}>
                            <%= friend.name %>
                          </button>
                        </li>
                      </ul>
                    <% else %>
                      <p class="italic">None of your friends are online</p>
                    <% end %>
                  </div>
                <% else %>
                  <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                    <div>
                      <button
                        phx-click="include_friends_locations"
                        class="font-semibold text-gray-900"
                      >
                        Include friends <span class="absolute inset-0"></span>
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
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
       sharing_location: false,
       include_friends_locations: false,
       friends: [],
       tracking: nil
     ), layout: false}
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
     |> push_event("go_to_user", %{type: :current_user})}
  end

  @impl true
  def handle_event("track_user", %{"user_id" => user_id}, socket) when is_integer(user_id) do
    {:noreply,
     socket
     |> assign(tracking: user_id)
     |> push_event("go_to_user", %{type: :friend, user_id: user_id})}
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
       push_event(socket, "user_new_location", %{
         type: :current_user,
         location: location,
         go_to: socket.assigns.tracking == :current_user
       })}
    else
      {:noreply,
       push_event(socket, "user_new_location", %{
         type: :friend,
         user_id: user_id,
         location: location,
         go_to: socket.assigns.tracking == user_id
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
