# RouteHub Infra

This repository contains the files to set up a simple cluster on [Hetzner](https://www.hetzner.com/) using [OpenTofu](https://opentofu.org/).

## Requirements

* A [Hetzner Cloud account](https://console.hetzner.cloud/).
* The Hetzner Cloud command-line interface ([version 1.64.1](https://github.com/hetznercloud/cli/releases/tag/v1.64.1)). While not strictly required, it is recommended.
* The OpenTofu command-line interface ([version 1.11.6](https://github.com/opentofu/opentofu/releases/tag/v1.11.6)).

## Hetzner Project

Create a new Hetzner Cloud project with a representative name. In this example, we will use **"RouteHub"**. Then, generate an [API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/).

Once you have created the project and the API token, the next step is to set up a context in the Hetzner CLI by running the following command. For the context name, use something similar to the project name (e.g. `routehub`), as they will be linked by the API token when prompted.

```bash
hcloud context create routehub
```

You can verify the configuration with the following command, which should return a list of available locations:

```bash
hcloud location list
```

## SSH Setup

In this section, we will create and configure the SSH key used to access the server(s) once they are running.

The following command creates a new SSH key. You can skip this step if you already have a key you wish to use.

```bash
ssh-keygen -t ed25519 -C "root@routehub" -f ~/.ssh/for_routehub_root
```

Next, upload the **public** SSH key to Hetzner so it can be injected into the servers upon creation. We are using the name **"main"** here, but feel free to change it.

```bash
hcloud ssh-key create --name main --public-key-from-file ~/.ssh/for_routehub_root.pub
```
