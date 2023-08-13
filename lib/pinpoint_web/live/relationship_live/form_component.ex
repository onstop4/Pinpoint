defmodule PinpointWeb.RelationshipLive.FormComponent do
  alias Pinpoint.Accounts
  use PinpointWeb, :live_component

  alias Pinpoint.Relationships.RelationshipRepo

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
  # def update(%{other_user: other_user} = assigns, socket) do
  #   changeset = Accounts.change_user_email(other_user)

  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_form(changeset)}
  # end

  # @impl true
  # def handle_event("validate", %{"other_user" => other_user_params}, socket) do
  #   changeset =
  #     socket.assigns.other_user
  #     |> Foos.change_foo(other_user_params)
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
         other_user when not is_nil(other_user) <-
           Accounts.get_user_by_email(recipient_email),
         nil <- RelationshipRepo.get_relationship(other_user.id, current_user.id),
         {:ok, _} <-
           RelationshipRepo.create_relationship(%{
             from_id: current_user.id,
             to_id: other_user.id,
             status: :pending_friend
           }) do
      notify_parent({:new_friend_request, other_user})

      {:noreply,
       socket
       |> put_flash(:info, "Sent friend request.")
       |> push_patch(to: socket.assigns.patch)}
    else
      _ ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Could not send request. Make sure you entered a valid email address that is associated with an account that hasn't blocked you."
         )}
    end
  end

  # defp save_relationship(socket, :new, %{"email" => recipient_email}) do
  #   current_user = socket.assigns.current_user

  #   with other_user when not is_nil(current_user) <-
  #          Accounts.get_user_by_email(recipient_email),
  #        {:ok, _} <- Relationships.create_friend_request(current_user, other_user) do
  #     notify_parent({:new_friend_request, other_user})

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
