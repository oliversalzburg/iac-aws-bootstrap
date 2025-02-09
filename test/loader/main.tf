data "external" "whoami" { program = ["/usr/bin/env", "bash", "-c", "--", "echo {\\\"stdout\\\":\\\"$(whoami)\\\"}"] }
data "external" "hostname" { program = ["/usr/bin/env", "bash", "-c", "--", "echo {\\\"stdout\\\":\\\"$(hostname)\\\"}"] }

resource "random_uuid" "capture_flag" {}
resource "local_file" "capture_flag" {
  content  = "CAPTURED ${timestamp()} ${data.external.whoami.result.stdout}@${data.external.hostname.result.stdout}:${path.cwd}"
  filename = random_uuid.capture_flag.result
}

resource "random_uuid" "flag" {}
resource "local_file" "flag" {
  content  = "LEGALLY OWNED ${timestamp()} ${data.external.whoami.result.stdout}@${data.external.hostname.result.stdout}:${path.cwd}"
  filename = random_uuid.flag.result
}
