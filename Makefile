.PHONY: docs docs-check docs-preview

TERRAFORM_DOCS ?= terraform-docs
TF_DOCS_MODULES := . examples/full examples/hetzner

docs:
	@for module in $(TF_DOCS_MODULES); do \
		$(TERRAFORM_DOCS) "$$module"; \
	done

docs-check:
	@for module in $(TF_DOCS_MODULES); do \
		$(TERRAFORM_DOCS) --output-check "$$module"; \
	done

docs-preview:
	@$(TERRAFORM_DOCS) --output-file "" .
