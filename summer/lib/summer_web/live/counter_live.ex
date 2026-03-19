defmodule SummerWeb.CounterLive do
  use SummerWeb, :live_view
  alias Summer.Counter

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:counter, Counter.new("0"))
     |> assign(:input, "")
     |> assign(:message, "")}
  end

  def handle_event("update_input", %{"input" => value}, socket) do
    {:noreply, assign(socket, :input, value)}
  end

  def handle_event("initialize", _params, socket) do
    case Integer.parse(socket.assigns.input) do
      {num, ""} ->
        {:noreply,
         socket
         |> assign(:counter, num)
         |> assign(:input, "")
         |> assign(:message, "Counter initialized to #{num}")}

      _ ->
        {:noreply, assign(socket, :message, "Invalid number")}
    end
  end

  def handle_event("add", %{"amount" => amount_str}, socket) do
    case Integer.parse(amount_str) do
      {amount, ""} ->
        new_counter = Counter.add(socket.assigns.counter, amount)

        {:noreply,
         socket
         |> assign(:counter, new_counter)
         |> assign(:message, Counter.show(new_counter))}

      _ ->
        {:noreply, assign(socket, :message, "Invalid amount")}
    end
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:counter, 0)
     |> assign(:input, "")
     |> assign(:message, "Counter reset")}
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen bg-gray-100">
      <div class="bg-white rounded-lg shadow-lg p-8 max-w-md w-full">
        <h1 class="text-3xl font-bold text-center mb-8 text-gray-800">Counter</h1>

        <!-- Current Counter Display -->
        <div class="bg-blue-50 rounded-lg p-6 mb-6 text-center">
          <p class="text-sm text-gray-600 mb-2">Current Value</p>
          <p class="text-5xl font-bold text-blue-600"><%= @counter %></p>
        </div>

        <!-- Initialize Counter -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Initialize Counter
          </label>
          <div class="flex gap-2">
            <input
              type="number"
              name="input"
              value={@input}
              phx-change="update_input"
              placeholder="Enter number"
              class="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <button
              phx-click="initialize"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            >
              Set
            </button>
          </div>
        </div>

        <!-- Add Buttons -->
        <div class="grid grid-cols-2 gap-3 mb-6">
          <button
            phx-click="add"
            phx-value-amount="1"
            class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-medium"
          >
            +1
          </button>
          <button
            phx-click="add"
            phx-value-amount="10"
            class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-medium"
          >
            +10
          </button>
        </div>

        <!-- Reset Button -->
        <button
          phx-click="reset"
          class="w-full px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition font-medium mb-6"
        >
          Reset
        </button>

        <!-- Message Display -->
        <%= if @message != "" do %>
          <div class="bg-purple-50 border border-purple-200 rounded-lg p-4 text-center">
            <p class="text-purple-800 font-medium"><%= @message %></p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
