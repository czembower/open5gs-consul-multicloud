resource "consul_autopilot_config" "this" {
  cleanup_dead_servers   = true
  last_contact_threshold = "5s"
  max_trailing_logs      = 500
}
