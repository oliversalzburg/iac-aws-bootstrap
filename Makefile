docs:
	terraform-docs markdown table --output-file README.md --output-mode inject .

lock:
	terraform init -upgrade -backend=false

pretty:
	terraform fmt -recursive .

validate:
	terraform validate
