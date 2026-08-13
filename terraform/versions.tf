terraform {
  # 1.4+ is required for the built-in `terraform_data` resource used by the
  # provider-agnostic module skeletons.
  required_version = ">= 1.6.0"

  # Intentionally empty. Concrete providers are introduced per-spec and always
  # declared inside the module that needs them, plus mirrored here. See
  # docs/adr/0001-provider-agnostic-baseline.md.
  required_providers {}
}
