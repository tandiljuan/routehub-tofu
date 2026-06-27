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

If the plan is correct and you are satisfied with the proposed changes, run the following command to deploy the resources:

```bash
tofu apply
```

During the initial deployment, a race condition may occur between server creation and network configuration, potentially leaving the internal network improperly initialized. To ensure stability, is recommended to reboot the servers after the first apply:

```bash
for i in $(tofu output --json server_ipv4 | jq -r 'keys[]'); do
    echo ">> Rebooting Hetzner server '${i}'"
    hcloud server reboot "${i}"
done
```

## Verification

Assuming OpenTofu applied the changes successfully, you should now have all the listed servers up and running. You can verify this by running the command below, which attempts to establish an SSH connection to the manager server and outputs a success or failure message.

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

#### SSH Setup

Below is a script to add the new servers to your SSH configuration file. Note that the options `StrictHostKeyChecking no` and `UserKnownHostsFile /dev/null` are intended only for ephemeral or disposable environments, remove them if you are configuring a production environment.

```bash
PROXY_JUMP=''
tofu output --json server_ipv4 |
jq -r 'to_entries[] | "\(.key) \(.value)"' |
nl -v0 -w1 -s' ' |
while IFS=' ' read -r index key value; do
    if (( $index == 0 )); then
        PROXY_JUMP="${key}"
        OPTIONS='ConnectTimeout 5'
    else
        OPTIONS=$(printf "ProxyJump ${PROXY_JUMP}\n  ServerAliveInterval 60\n  ServerAliveCountMax 3")
    fi
    cat <<EOF >> ~/.ssh/config

Host ${key}
  Hostname ${value}
  User root
  IdentityFile ~/.ssh/for_routehub_root
  ForwardAgent yes
  IdentitiesOnly yes
  StrictHostKeyChecking no # Not for production
  UserKnownHostsFile /dev/null # Not for production
  LogLevel QUIET
  ${OPTIONS}
EOF
done
```

### Load Balancer

If you're using the default load balancer settings, a service must be listening on port 80. Run an [Nginx](https://hub.docker.com/_/nginx) container on the manager server to provide that service by executing the command below.

```bash
ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o IdentitiesOnly=yes \
    -i ~/.ssh/for_routehub_root \
    -q root@$(tofu output --json server_ipv4 | jq -r '."rh-mng"') bash -c \
'export DEBIAN_FRONTEND=noninteractive \
&& apt-get -y update \
&& apt-get -y install docker.io \
&& docker run --rm --detach --publish 80:80 nginx:alpine'
```

It may take a few seconds for the load balancer to detect the new service. Run the command below and wait until the load balancer's status (health) shows **healthy** or **mixed**.

```bash
watch hcloud load-balancer list
```

Once the load balancer is ready, curl its public IP with the command below. You should see the standard "Welcome to nginx!" page.

```bash
curl $(tofu output --json load_balancer | jq -r '.ipv4')
```

## Destroy

Once you have finished testing or learning OpenTofu, you can delete all resources to avoid unnecessary costs with the following command:

```bash
tofu destroy
```
