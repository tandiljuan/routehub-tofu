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

## Initialization

Now is time to initialize the directory containing the OpenTofu configuration files. This process will, among other things, install the [Hetzner Cloud provider](https://github.com/hetznercloud/terraform-provider-hcloud) plugin.

The command will prompt you for values for any variables that do not have a default. To simplify this, you can define the [values in a file](https://opentofu.org/docs/language/values/variables/#variable-definitions-tfvars-files).

```bash
tofu init
```

## Plan

After initialization, create a plan. OpenTofu will display the changes it intends to make to your infrastructure.

```bash
tofu plan
```

## Apply

If the plan looks correct and you are satisfied with the proposed changes, run the following command to deploy the resources.

```bash
tofu apply
```

## Verification

Assuming OpenTofu applied the changes successfully, you should now have all the servers defined in the list up and running. You can verify this by running the command below, which attempts to establish an SSH connection to the manager and returns a success or failure message.

```bash
ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -i ~/.ssh/for_routehub_root \
    -q root@$(tofu output --json server_ipv4 | jq -r '."rh-mng"') exit \
&& echo ">> SSH OK :-)" || echo ">> SSH ERROR :-("
```

**Expected output:**

```
>> SSH OK :-)
```

You can also use the Hetzner Cloud CLI to list the newly created server.

```bash
hcloud server list
```

## Destroy

Once you have finished testing or learning OpenTofu, you can delete all resources to avoid unnecessary costs with the following command:

```bash
tofu destroy
```
