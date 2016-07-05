defmodule Matrix do
  defmodule Inspect do
    @doc false
    def inspect(matrix, opts) do
      "#Matrix-(#{matrix.dimensions |> Enum.join("×")})#{inspect_contents(matrix)}"
    end

    defp inspect_contents(matrix) do
      contents_inspect = 
        matrix
        |> Matrix.to_list
        |> Enum.map(fn row -> 
          row 
          |> Enum.map(fn elem -> 
            elem
            |> inspect
            |> String.pad_leading(8)
          end) 
          |> Enum.join(",") 
        end)
      #  |> Enum.join("│\n│")
      top_row_length = String.length(List.first(contents_inspect))
      bottom_row_length = String.length(List.last(contents_inspect))
      top = "\n┌#{String.pad_trailing("", top_row_length)}┐\n│"
      bottom = "│\n└#{String.pad_trailing("", bottom_row_length)}┘\n"
      contents_str = contents_inspect |> Enum.join("│\n│")
      "#{top}#{contents_str}#{bottom}"
    end
  end

  @doc """
  Creates a new matrix of dimensions `width` x `height`.

  Optionally pass in a third argument, which will be the values the matrix will be filled with. (default: `0`)
  """
  def new(width, height, identity \\ 0) when width > 0 and height > 0 do
    %Tensor{identity: identity, dimensions: [width, height]}
  end

  @doc """
  Converts a matrix to a list of lists.
  """
  def to_list(matrix) do
    Tensor.to_list(matrix)
  end

  @doc """
  Creates an 'identity' matrix.

  This is a square matrix of size `size` that has the `diag_identity` value (default: `1`) at the diagonal, and the rest is `0`.
  Optionally pass in a third argument, which is the value the rest of the elements in the matrix will be set to.
  """
  def identity(diag_identity \\ 1, size, rest_identity \\ 0) when size > 0 do
    elems = Stream.cycle([diag_identity]) |> Enum.take(size)
    diag(elems, rest_identity)
  end

  @doc """
  Creates a square matrix where the diagonal elements are filled with the elements of `list`.
  The second argument is an optional `identity` to be used for all elements not part of the diagonal.
  """
  def diag(list = [_|_], identity \\ 0) when is_list(list) do
    size = length(list)
    matrix = new(size, size, identity)
    list
    |> Enum.with_index
    |> Enum.reduce(matrix, fn {e, i}, mat -> 
      put_in(mat, [i,i], e)
    end)
  end

  @doc """ 
  True if the matrix is square and the same as its transpose.
  """
  def symmetric?(matrix = %Tensor{dimensions: [s,s]}) do
    matrix == matrix |> transpose
  end

  def symmetric?(matrix = %Tensor{dimensions: [_,_]}), do: false

  def transpose(matrix = %Tensor{dimensions: [w,h]}) do
    new_contents = Enum.reduce(matrix.contents, %{}, fn {row_key, row_map}, new_row_map -> 
      Enum.reduce(row_map, new_row_map, fn {col_key, value}, new_row_map ->
        map = Map.put_new(new_row_map, col_key, %{})
        put_in(map, [col_key, row_key], value)
      end)
    end)
    %Tensor{identity: matrix.identity, contents: new_contents, dimensions: [h, w]}
  end

  @doc """
  Takes a vector, and returns a 1×`n` matrix.
  """
  def row_matrix(vector = %Tensor{dimensions: [_]}) do
    Tensor.lift(vector)
  end

  @doc """
  Takes a vector, and returns a `n`×1 matrix.
  """
  def column_matrix(vector = %Tensor{dimensions: [_]}) do
    vector
    |> Tensor.lift
    |> Matrix.transpose
  end

  def rows(matrix = %Tensor{dimensions: [w,h]}) do
    for i <- 0..h-1 do
      matrix[i]
    end
  end

  def columns(matrix = %Tensor{dimensions: [_,_]}) do
    matrix
    |> transpose
    |> rows
  end

  # Scalar addition
  def add(matrix, num) when is_number(num) do 
    Tensor.map(matrix, fn val -> val + num end)
  end

  # Scalar multiplication
  def mult(matrix, num) when is_number(num) do 
    Tensor.map(matrix, fn val -> val * num end)
  end

  @doc """
  Calculates the Matrix Multiplication of `a` * `b`.

  This will only work as long as the height of `a` is the same as the width of `b`.

  This operation internally builds up a list-of-lists, and finally transforms that back to a matrix.
  """
  # TODO: What to do with identity?
  def dot_product(a = %Tensor{dimensions: [m,n]}, b = %Tensor{dimensions: [n,p]}) do
    b_t = transpose(b)
    list_of_lists = 
      for r <- (0..m-1) do
        for c <- (0..p-1) do
          Vector.dot_product(a[r], b_t[c])
        end
      end
    IO.inspect(list_of_lists)

    Tensor.new(list_of_lists, [m, p])
  end


  def dot_product(a = %Tensor{dimensions: [_,_]}, b = %Tensor{dimensions: [_,_]}) do
    raise "Cannot compute dot product if the height of matrix `a` does not match the width of matrix `b`!"
  end

end
