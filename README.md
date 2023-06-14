# Usage

```elixir
%> iex -S mix

iex> Jobber.start_job(work: ok_job)

iex> Jobber.start_job(work: error_job)

iex> Jobber.start_job(work: exception_job)
```