# Throttling for abusive clients. Keys live in Rails.cache (memory_store on
# free tier, swapped for Redis on bigger tiers).
class Rack::Attack
  # Block lists / safelists first.
  safelist("allow-localhost") do |req|
    %w[127.0.0.1 ::1].include?(req.ip)
  end

  # 5 login attempts per IP per 20 seconds — catches brute force.
  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/api/v1/login" && req.post?
  end

  # 5 signups per IP per minute.
  throttle("signup/ip", limit: 5, period: 1.minute) do |req|
    req.ip if (req.path == "/api/v1/signup" || req.path == "/signup") && req.post?
  end

  # 30 requests / 10s per IP overall — generous default.
  throttle("api/ip", limit: 30, period: 10.seconds) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = ->(_env) {
    [429, { "Content-Type" => "application/json" }, [{ error: "Rate limit exceeded. Slow down." }.to_json]]
  }
end

Rails.application.config.middleware.use Rack::Attack
