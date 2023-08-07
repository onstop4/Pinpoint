defmodule PinpointWeb.RelationshipLive.FormComponent do
  alias Pinpoint.Accounts
  use PinpointWeb, :live_component

  alias Pinpoint.Relationships

  @impl true
  def render(assigns) do
    form = to_form(%{"email" => ""})
    assigns = Map.put(assigns, :form, form)

    ~H"""
    <div>
      <.flash_group flash={@flash} />
      <.header>
        <%= @title %>
        <:subtitle>Use this form to send a new friend request.</:subtitle>
      </.header>

      <.simple_form for={@form} id="friend_request_form" phx-target={@myself} phx-submit="save">
        <.input field={@form[:email]} type="text" label="Email" />
        <:actions>
          <.button phx-disable-with="Sending...">Send request</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # @impl true
  # def update(%{recipient_user: recipient_user} = assigns, socket) do
  #   changeset = Accounts.change_user_email(recipient_user)

  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_form(changeset)}
  # end

  # @impl true
  # def handle_event("validate", %{"recipient_user" => recipient_user_params}, socket) do
  #   changeset =
  #     socket.assigns.recipient_user
  #     |> Foos.change_foo(recipient_user_params)
  #     |> Map.put(:action, :validate)

  #   {:noreply, assign_form(socket, changeset)}
  # end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("save", %{"email" => recipient_email}, socket) do
    current_user = socket.assigns.current_user

    with current_user_email when current_user_email != recipient_email <- current_user.email,
         recipient_user when not is_nil(recipient_user) <-
           Accounts.get_user_by_email(recipient_email),
         {:ok, _} <-
           Relationships.create_relationship(%{
             from_id: current_user.id,
             to_id: recipient_user.id,
             status: :pending_friend
           }) do
      notify_parent({:new_friend_request, recipient_user})

      IO.puts("success. will navigate to #{socket.assigns.patch}")

      {:noreply,
       socket
       |> put_flash(:info, "Sent friend request.")
       |> push_patch(to: socket.assigns.patch)}
    else
      _ ->
        IO.puts("failure")

        {:noreply,
         put_flash(
           socket,
           :error,
           "Could not send request. Make sure you entered a valid email address that is associated with an account that's not your own."
         )}
    end
  end

  # defp save_relationship(socket, :new, %{"email" => recipient_email}) do
  #   current_user = socket.assigns.current_user

  #   with recipient_user when not is_nil(current_user) <-
  #          Accounts.get_user_by_email(recipient_email),
  #        {:ok, _} <- Relationships.create_friend_request(current_user, recipient_user) do
  #     notify_parent({:new_friend_request, recipient_user})

  #     {:noreply,
  #      socket
  #      |> put_flash(:info, "Sent friend request")
  #      |> push_patch(to: socket.assigns.patch)}
  #   else
  #     _ -> {:noreply, assign_form(socket, %{})}
  #   end

  # case Relationships.create_relationship(relationship_params) do
  #   {:ok, relationship} ->
  #     notify_parent({:saved, relationship})

  #     {:noreply,
  #      socket
  #      |> put_flash(:info, "Relationship created successfully")
  #      |> push_patch(to: socket.assigns.patch)}

  #   {:error, %Ecto.Changeset{} = changeset} ->
  #     {:noreply, assign_form(socket, changeset)}
  # end
  # end

  # defp assign_form(socket, %Ecto.Changeset{} = changeset) do
  #   assign(socket, :form, to_form(changeset))
  # end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
