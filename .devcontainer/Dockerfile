FROM mcr.microsoft.com/devcontainers/base:bookworm

# Install base dependencies for repository setup.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates curl git-lfs gnupg lsb-release unzip \
	&& install -m 0755 -d /etc/apt/keyrings \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install Terraform from the HashiCorp apt repository.
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg \
	&& chmod a+r /etc/apt/keyrings/hashicorp-archive-keyring.gpg \
	&& echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo \"$VERSION_CODENAME\") main" > /etc/apt/sources.list.d/hashicorp.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends terraform \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Install Google Cloud CLI from the Google apt repository.
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg \
	&& chmod a+r /etc/apt/keyrings/cloud.google.gpg \
	&& echo "deb [signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends google-cloud-cli \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

## Install dig
RUN apt-get update \
	&& apt-get install -y --no-install-recommends dnsutils