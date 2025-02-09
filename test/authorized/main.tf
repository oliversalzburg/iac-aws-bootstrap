resource "random_uuid" "test" {}
resource "local_file" "test" {
  content  = <<-EOT
    spawn ${var.aws_cli_cmd}
    expect {
        timeout { exit 1 }
        eof
    }

    lassign [wait] pid spawnid os_error_flag value

    if {$os_error_flag == 0} {
        puts "exit status: $value"
        if {$value == 0} { exit 0 }
    } else {
        puts "errno: $value"
    }
    exit 1
    EOT
  filename = random_uuid.test.result
}

resource "null_resource" "test" {
  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "expect"]
    command     = local_file.test.filename
  }
}
