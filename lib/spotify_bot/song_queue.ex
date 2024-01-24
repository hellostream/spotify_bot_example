defmodule SpotifyBot.SongQueue do
  @moduledoc false
  use GenServer

  @default_max_total 100
  @default_max_per_user 2
  @default_allow_consecutive true

  @doc """
  Start the song queue server.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Add a track to the queue.
  """
  @spec add(String.t(), String.t()) ::
          :ok | {:error, :max_total} | {:error, :max_per_user} | {:error, :no_consecutive}
  def add(track_id, user) do
    GenServer.call(__MODULE__, {:add, track_id, user})
  end

  # ----------------------------------------------------------------------------
  # Callbacks
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init(opts) do
    state = %{
      queue: [],
      songs_per_user: Keyword.get(opts, :max_per_user, @default_max_per_user),
      max_total: Keyword.get(opts, :max_total, @default_max_total),
      allow_consecutive?: Keyword.get(opts, :allow_consecutive?, @default_allow_consecutive)
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:add, track_id, user}, _from, state) do
    total = Enum.count(state.queue)

    user_count =
      Enum.reduce(state.queue, 0, fn {u, _}, acc ->
        if user == u, do: acc + 1, else: acc
      end)

    cond do
      total >= state.max_total ->
        {:reply, {:error, :max_total}, state}

      user_count >= state.max_per_user ->
        {:reply, {:error, :max_per_user}, state}

      match?({^user, _}, hd(state.queue)) and not state.allow_consecutive? ->
        {:reply, {:error, :no_consecutive}, state}

      true ->
        {:reply, :ok, %{state | queue: [{user, track_id} | state.queue]}}
    end
  end
end
