provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      iac-subject   = "default"
      iac-test-run  = timestamp()
      owner-manager = "iac-aws-bootstrap"
    }
  }
}
provider "aws" {
  alias  = "global"
  region = "us-east-1"
  default_tags {
    tags = {
      iac-subject   = "global"
      iac-test-run  = timestamp()
      owner-manager = "iac-aws-bootstrap"
    }
  }
}
provider "aws" {
  alias  = "replica"
  region = "eu-north-1"
  default_tags {
    tags = {
      iac-subject   = "replica"
      iac-test-run  = timestamp()
      owner-manager = "iac-aws-bootstrap"
    }
  }
}
provider "aws" {
  alias  = "keystore"
  region = "ca-central-1"
  default_tags {
    tags = {
      iac-subject   = "keystore"
      iac-test-run  = timestamp()
      owner-manager = "iac-aws-bootstrap"
    }
  }
}


run "execute" {
  variables {
    force_kms_key_deletion_window_in_days = 7
  }
}

run "loader" {
  module {
    source = "./test/loader"
  }
  variables {
    state_id = run.execute.s3.state.id
  }
}

run "pass_s3_put_sse_kms_cmk" {
  module {
    source = "./test/authorized"
  }
  variables {
    aws_cli_cmd = <<-EOT
    aws s3 cp \
      ${run.loader.flag_filename} \
      s3://${run.execute.s3.state.id}/${run.loader.flag_filename} \
      --sse=aws:kms \
      --sse-kms-key-id=${run.execute.kms.state.id}
    EOT
  }
}

run "fail_s3_put_default_sse" {
  module {
    source = "./test/unauthorized"
  }
  variables {
    aws_cli_cmd = <<-EOT
    aws s3 cp \
      ${run.loader.capture_flag_filename} \
      s3://${run.execute.s3.state.id}/${run.loader.capture_flag_filename} \
      --sse=aws:kms
    EOT
  }
}

run "fail_s3_delete_default_sse" {
  module {
    source = "./test/unauthorized"
  }
  variables {
    aws_cli_cmd = <<-EOT
    aws s3 rm \
      ${run.loader.flag_filename} \
      --sse=aws:kms
    EOT
  }
}

