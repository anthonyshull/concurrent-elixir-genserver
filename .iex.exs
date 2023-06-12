ok_job = fn ->
  Process.sleep(1000)
  {:ok, []}
end

error_job = fn ->
  Process.sleep(1000)
  :error
end

exception_job = fn ->
  Process.sleep(1000)
  raise "exception"
end
