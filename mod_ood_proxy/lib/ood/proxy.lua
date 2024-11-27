--[[
  set_reverse_proxy

  Modify a given request to utilize mod_proxy for reverse proxying.
--]]
function set_reverse_proxy(r, conn)
  -- find protocol used by parsing the request headers
  local protocol = (r.headers_in['Upgrade'] and "ws://" or "http://")


  -- if the port is an odd number, upgrade to use secure sockets
  local port = r.subprocess_env['MATCH_PORT']
  if port then
    if port % 2 ~= 0 then
      protocol = (r.headers_in['Upgrade'] and "wss://" or "https://")
    end
  end

  -- define reverse proxy destination using connection object
  if conn.socket then
    r.handler = "proxy:unix:" .. conn.socket .. "|" .. protocol .. "localhost"
  else
    r.handler = "proxy:" .. protocol .. conn.server
  end

  r.filename = conn.uri

  -- include useful information for the backend server

  -- provide the protocol used
  r.headers_in['X-Forwarded-Proto'] = r.is_https and "https" or "http"

  -- provide the authenticated user name
  r.headers_in['X-Forwarded-User'] = conn.user or ""

  -- **required** by PUN when initializing app
  r.headers_in['X-Forwarded-Escaped-Uri'] = r:escape(conn.uri)

  -- set timestamp of reverse proxy initialization as CGI variable for later hooks (i.e., analytics)
  r.subprocess_env['OOD_TIME_BEGIN_PROXY'] = r:clock()
end

return {
  set_reverse_proxy = set_reverse_proxy
}
