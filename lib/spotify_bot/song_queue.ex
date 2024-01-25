defmodule SpotifyBot.SongQueue do
  @moduledoc false
  use GenServer

  # Defaults.
  @allow_user_consecutive false
  @allow_consecutive false
  @allow_duplicates false
  @max_per_user 2
  @max_total 100

  @doc """
  Start the song queue server.

  ## Options

   * `:max_total` - The max total queue size. Defaults to `100`.
   * `:max_per_user` - The max number of songs per user. Defaults to `2`.
   * `:allow_user_consecutive?` - Whether we allow consecutives per user. Defaults to `false`.
   * `:allow_consecutive?` - Whether we allow consecutives per user. Defaults to `false`.
   * `:allow_duplicates?` - The max total queue size. Defaults to `false`.

  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Add a track to the queue.
  """
  @spec add(String.t(), String.t()) ::
          :ok
          | {:error, :max_total}
          | {:error, :max_per_user}
          | {:error, :no_consecutive}
          | {:error, :no_user_consecutive}
          | {:error, :no_duplicates}
  def add(track_id, user) do
    GenServer.call(__MODULE__, {:add, track_id, user})
  end

  @doc """
  Remove a track from the queue.
  """
  @spec remove(String.t()) :: :ok
  def remove(track_id) do
    GenServer.cast(__MODULE__, {:remove, track_id})
  end

  @doc """
  Remove all tracks for a user.
  """
  @spec remove_user(String.t()) :: :ok
  def remove_user(user) do
    GenServer.cast(__MODULE__, {:remove_user, user})
  end

  @doc """
  Get the size of the current queue.
  """
  @spec size() :: non_neg_integer()
  def size do
    GenServer.call(__MODULE__, :size)
  end

  # ----------------------------------------------------------------------------
  # Callbacks
  # ----------------------------------------------------------------------------

  @doc false
  @impl GenServer
  def init(opts) do
    state = %{
      allow_consecutive?: Keyword.get(opts, :allow_consecutive?, @allow_consecutive),
      allow_user_consecutive?:
        Keyword.get(opts, :allow_user_consecutive?, @allow_user_consecutive),
      allow_duplicates?: Keyword.get(opts, :allow_duplicates?, @allow_duplicates),
      max_total: Keyword.get(opts, :max_total, @max_total),
      songs_per_user: Keyword.get(opts, :max_per_user, @max_per_user),
      count: 0,
      queue: []
    }

    {:ok, state}
  end

  @doc false
  @impl GenServer
  def handle_cast({:remove, track_id}, state) do
    state =
      if List.keymember?(state.queue, track_id, 0) do
        # I know this is stupid. I want to remove the last occurence and I
        # don't want to use my brain. I'm tired. Leave me alone.
        queue = Enum.reverse(state.queue) |> List.keydelete(track_id, 0)
        %{state | count: state.count - 1, queue: Enum.reverse(queue)}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:remove_user, user}, state) do
    if List.keymember?(state.queue, user, 1) do
      {queue, deleted} =
        Enum.reduce(state.queue, {[], 0}, fn {track, u}, {queue, deleted} ->
          if user == u, do: {queue, deleted + 1}, else: {[{track, u} | queue], deleted}
        end)

      {:noreply, %{state | count: state.count - deleted, queue: queue}}
    else
      {:noreply, state}
    end
  end

  @doc false
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

      List.keymember?(state.queue, track_id, 0) and not state.allow_duplicates? ->
        {:reply, {:error, :no_duplicates}, state}

      match?({_, ^user}, hd(state.queue)) and not state.allow_consecutive? ->
        {:reply, {:error, :no_consecutive}, state}

      true ->
        {:reply, :ok, %{state | count: state.count + 1, queue: [{track_id, user} | state.queue]}}
    end
  end

  def handle_call(:size, _from, state) do
    {:reply, state.count, state}
  end
end
