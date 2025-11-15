local prometheus = require("prometheus").init("prometheus_metrics")
local ngx = ngx

-- metrics
local req_counter = prometheus:counter("nginx_requests_total", "Total HTTP requests", {"host", "status"})
local req_latency = prometheus:histogram("nginx_request_duration_seconds", "Request latency", {"host"})

-- increment counters using ngx var
local host = ngx.var.host or "unknown"
local status = tostring(ngx.status or 200)
req_counter:inc(1, {host, status})
req_latency:observe(tonumber(ngx.var.request_time) or 0, {host})

-- if request to /metrics, output all metrics
if ngx.var.uri == "/metrics" then
  ngx.header["Content-Type"] = "text/plain; version=0.0.4"
  ngx.say(prometheus:collect())
  return
end
