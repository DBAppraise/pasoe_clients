define variable n as integer no-undo.

for each customer no-lock:
  n = 0.
  for each order of customer:
    n = n + 1.
  end.
  display customer.custNum n.
end.
