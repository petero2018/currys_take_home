# Docker image for running Terraform-based infrastructure commands
FROM mcr.microsoft.com/azure-cli:2.58.0

ARG TERRAFORM_VERSION=1.7.5
ENV TERRAFORM_VERSION=${TERRAFORM_VERSION}

# Install Terraform and common tooling
RUN apk update \
    && apk add --no-cache bash curl unzip git make ca-certificates \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && rm -rf /var/cache/apk/*

# ensure every command automatically sources infrastructure/.env when present
RUN cat <<'EOF' >/usr/local/bin/with-infra-env.sh && chmod +x /usr/local/bin/with-infra-env.sh
#!/usr/bin/env bash
set -e
ENV_FILE="/workspace/infrastructure/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  . "$ENV_FILE"
  set +a
fi
exec "$@"
EOF

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/with-infra-env.sh"]
CMD ["bash"]
