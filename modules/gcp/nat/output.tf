output "this" {
  value = {
    eip = merge(
      google_compute_address.this,
      { public_ip = google_compute_address.this.address }
    )
  }
}
