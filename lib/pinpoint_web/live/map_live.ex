defmodule PinpointWeb.MapLive do
  alias Pinpoint.Locations
  alias Pinpoint.Locations.{Broadcaster, Subscribing}
  alias Pinpoint.Accounts
  use PinpointWeb, :live_view

  @safe_user_columns [:id, :name]

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
                  <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center rounded-lg">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="32"
                      height="32"
                      fill="currentColor"
                      class="bi bi-broadcast"
                      viewBox="0 0 16 16"
                    >
                      <path d="M3.05 3.05a7 7 0 0 0 0 9.9.5.5 0 0 1-.707.707 8 8 0 0 1 0-11.314.5.5 0 0 1 .707.707zm2.122 2.122a4 4 0 0 0 0 5.656.5.5 0 1 1-.708.708 5 5 0 0 1 0-7.072.5.5 0 0 1 .708.708zm5.656-.708a.5.5 0 0 1 .708 0 5 5 0 0 1 0 7.072.5.5 0 1 1-.708-.708 4 4 0 0 0 0-5.656.5.5 0 0 1 0-.708zm2.122-2.12a.5.5 0 0 1 .707 0 8 8 0 0 1 0 11.313.5.5 0 0 1-.707-.707 7 7 0 0 0 0-9.9.5.5 0 0 1 0-.707zM10 8a2 2 0 1 1-4 0 2 2 0 0 1 4 0z" />
                    </svg>
                  </div>
                  <div>
                    <%= if @broadcaster do %>
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
                    <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center rounded-lg">
                      <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="32"
                      height="32"
                      fill="currentColor"
                      class="bi bi-pin-map-fill"
                      viewBox="0 0 16 16"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M3.1 11.2a.5.5 0 0 1 .4-.2H6a.5.5 0 0 1 0 1H3.75L1.5 15h13l-2.25-3H10a.5.5 0 0 1 0-1h2.5a.5.5 0 0 1 .4.2l3 4a.5.5 0 0 1-.4.8H.5a.5.5 0 0 1-.4-.8l3-4z"
                        />
                        <path
                          fill-rule="evenodd"
                          d="M4 4a4 4 0 1 1 4.5 3.969V13.5a.5.5 0 0 1-1 0V7.97A4 4 0 0 1 4 3.999z"
                        />
                      </svg>
                    </div>
                    <div>
                      <button phx-click="stop_tracking" class="font-semibold text-gray-900">
                        Stop tracking <span class="absolute inset-0"></span>
                      </button>
                    </div>
                  </div>
                <% else %>
                  <%= if @current_user_is_sharing do %>
                    <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                      <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center rounded-lg">
                          <svg
                          xmlns="http://www.w3.org/2000/svg"
                          width="32"
                          height="32"
                          fill="currentColor"
                          class="bi bi-pin-map-fill"
                          viewBox="0 0 16 16"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M3.1 11.2a.5.5 0 0 1 .4-.2H6a.5.5 0 0 1 0 1H3.75L1.5 15h13l-2.25-3H10a.5.5 0 0 1 0-1h2.5a.5.5 0 0 1 .4.2l3 4a.5.5 0 0 1-.4.8H.5a.5.5 0 0 1-.4-.8l3-4z"
                          />
                          <path
                            fill-rule="evenodd"
                            d="M4 4a4 4 0 1 1 4.5 3.969V13.5a.5.5 0 0 1-1 0V7.97A4 4 0 0 1 4 3.999z"
                          />
                        </svg>
                      </div>
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
                    <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center rounded-lg">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="32"
                        height="32"
                        fill="currentColor"
                        class="bi bi-people-fill"
                        viewBox="0 0 16 16"
                      >
                        <path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.784 6A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216ZM4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z" />
                      </svg>
                    </div>
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
                        <span class="absolute inset-0"></span>
                      </button>
                    </div>
                  </div>
                  <div id="friends-list" class="px-6" style="display: none">
                    <%= if @online_friends != [] do %>
                      <ul :for={friend <- @online_friends}>
                        <li class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                          <button phx-click={JS.push("track_user", value: %{user_id: friend.id})}>
                            <%= friend.name %> <span class="absolute inset-0"></span>
                          </button>
                        </li>
                      </ul>
                    <% else %>
                      <p class="italic">None of your friends are sharing at the moment.</p>
                    <% end %>
                  </div>
                <% else %>
                  <div class="group relative flex gap-x-6 rounded-lg p-4 hover:bg-gray-50">
                    <div class="mt-1 flex h-11 w-11 flex-none items-center justify-center rounded-lg">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="32"
                        height="32"
                        fill="currentColor"
                        class="bi bi-people-fill"
                        viewBox="0 0 16 16"
                      >
                        <path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm-5.784 6A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216ZM4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z" />
                      </svg>
                    </div>
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
    Process.flag(:trap_exit, true)

    current_user_id = socket.assigns.current_user.id

    socket =
      assign(socket,
        page_title: "Map",
        broadcaster: nil,
        current_user_is_sharing: false,
        include_friends_locations: false,
        friends_ids: %{},
        online_friends: [],
        tracking: nil
      )

    socket =
      if connected?(socket) do
        Subscribing.subscribe(current_user_id)
        Subscribing.subscribe_to_personal(current_user_id)

        case Locations.get_info(current_user_id) do
          {_pid, location} when is_list(location) ->
            modify_socket_because_new_location(socket, current_user_id, location)

          _ ->
            socket
        end
      else
        socket
      end

    {:ok, socket, layout: {PinpointWeb.Layouts, :basic}}
  end

  @impl true
  def handle_event("start_sharing_location", _, socket) do
    with nil <- socket.assigns.broadcaster,
         {:ok, pid} <- Broadcaster.start_link(socket.assigns.current_user.id) do
      {:noreply,
       socket
       |> assign(broadcaster: pid)
       |> push_event("youve_started_sharing", %{})}
    end
  end

  @impl true
  def handle_event("stop_sharing_location", _, socket) do
    case socket.assigns.broadcaster do
      nil -> {:noreply, socket}
      _ -> {:noreply, modify_socket_and_stop_sharing(socket)}
    end
  end

  @impl true
  def handle_event("new_location", location = [x, y], socket)
      when is_number(x) and is_number(y) do
    if is_pid(socket.assigns.broadcaster) do
      Broadcaster.update_location(socket.assigns.broadcaster, location)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("include_friends_locations", _, socket) do
    friends =
      Pinpoint.Relationships.Finders.ListFriendsSharingLocations.find(
        socket.assigns.current_user.id,
        @safe_user_columns
      )

    {friends_ids, online_friends_and_locations} =
      friends
      |> Stream.map(fn user ->
        :ok = Subscribing.subscribe(user.id)

        case Locations.get_info(user.id) do
          {_pid, location} when is_list(location) ->
            {{user.id, true}, %{user: user, location: location}}

          _ ->
            {{user.id, false}, nil}
        end
      end)
      |> Enum.unzip()

    online_friends_and_locations = Enum.reject(online_friends_and_locations, &is_nil/1)
    online_friends = Enum.map(online_friends_and_locations, fn %{user: user} -> user end)

    {:noreply,
     socket
     |> assign(
       include_friends_locations: true,
       friends_ids: Map.new(friends_ids),
       online_friends: online_friends
     )
     |> push_event("update_friends_list", %{friends_and_locations: online_friends_and_locations})}
  end

  @impl true
  def handle_event("exclude_friends_locations", _, socket) do
    Enum.each(socket.assigns.friends_ids, fn {user_id, _status} ->
      Subscribing.unsubscribe(user_id)
    end)

    {:noreply,
     socket
     |> assign(
       include_friends_locations: false,
       friends_ids: MapSet.new(),
       online_friends: []
     )
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
  def handle_info({:updated_location, user_id, location}, socket) do
    {:noreply, modify_socket_because_new_location(socket, user_id, location)}
  end

  @impl true
  def handle_info({:stopped_sharing, user_id}, socket) do
    {:noreply, modify_socket_because_sharing_stopped(socket, user_id)}
  end

  @impl true
  def handle_info({:updated_sharing_status, user_id, true}, socket) do
    if socket.assigns.include_friends_locations do
      Subscribing.subscribe(user_id)
      socket = update(socket, :friends_ids, &Map.put(&1, user_id, false))

      case Locations.get_info(user_id) do
        nil ->
          {:noreply, socket}

        {_pid, location} ->
          {:noreply, modify_socket_because_new_location(socket, user_id, location)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:updated_sharing_status, user_id, false}, socket) do
    if socket.assigns.include_friends_locations do
      Subscribing.unsubscribe(user_id)

      {:noreply,
       socket
       |> update(:friends_ids, &Map.delete(&1, user_id))
       |> modify_socket_because_sharing_stopped(user_id)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:EXIT, process, reason}, socket) do
    if process == socket.assigns.broadcaster do
      {:noreply,
       socket
       |> put_flash(
         :error,
         case reason do
           :allow_alternate_broadcaster ->
             "You stopped sharing your location from this device because you started sharing from another device."

           _ ->
             "You stopped sharing your location from this device."
         end
       )
       |> modify_socket_and_stop_sharing(false)}
    else
      {:noreply, socket}
    end
  end

  defp modify_socket_because_new_location(socket, user_id, location) do
    cond do
      user_id == socket.assigns.current_user.id ->
        socket
        |> assign(current_user_is_sharing: true)
        |> push_event("user_new_location", %{type: :current_user, location: location})

      socket.assigns.include_friends_locations and socket.assigns.friends_ids[user_id] ->
        push_event(socket, "user_new_location", %{
          type: :friend,
          user_id: user_id,
          location: location
        })

      socket.assigns.include_friends_locations and socket.assigns.friends_ids[user_id] == false ->
        user = user_id |> Accounts.get_user!() |> Map.take(@safe_user_columns)

        socket
        |> update(
          :online_friends,
          fn friends ->
            Enum.sort_by([user | friends], &String.downcase(&1.name))
          end
        )
        |> update(:friends_ids, &Map.put(&1, user_id, true))
        |> push_event("user_started_sharing", %{type: :friend, user: user, location: location})

      true ->
        socket
    end
  end

  defp modify_socket_because_sharing_stopped(socket, user_id) do
    cond do
      user_id == socket.assigns.current_user.id ->
        socket
        |> assign(current_user_is_sharing: false)
        |> update(
          :tracking,
          fn
            :current_user -> nil
            tracking_else -> tracking_else
          end
        )
        |> push_event("user_stopped_sharing", %{type: :current_user})

      socket.assigns.include_friends_locations ->
        socket
        |> update(:online_friends, &Enum.reject(&1, fn user -> user.id == user_id end))
        |> update(:friends_ids, &Map.replace(&1, user_id, false))
        |> update(
          :tracking,
          fn
            ^user_id -> nil
            tracking_else -> tracking_else
          end
        )
        |> push_event("user_stopped_sharing", %{type: :friend, user_id: user_id})

      true ->
        socket
    end
  end

  defp modify_socket_and_stop_sharing(socket, kill_broadcaster \\ true) do
    if kill_broadcaster do
      try do
        Broadcaster.stop(socket.assigns.broadcaster)
      catch
        :exit, _ -> nil
      end
    end

    socket
    |> assign(broadcaster: nil)
    |> push_event("youve_stopped_sharing", %{})
  end

  defp toggle_friends_list(js \\ %JS{}) do
    js
    |> JS.toggle(to: "#friends-list")
    # The two steps below were adapted from
    # https://github.com/phoenixframework/phoenix_live_view/pull/1721#issuecomment-1083130244.
    |> JS.remove_class("rotate-90", to: "#toggle-friends-list-caret")
    |> JS.add_class("rotate-90", to: "#toggle-friends-list-caret:not(.rotate-90)")
  end
end
