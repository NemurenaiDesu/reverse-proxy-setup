### Usage example for Ubuntu:

```bash
DEBIAN_FRONTEND=noninteractive apt -y update && DEBIAN_FRONTEND=noninteractive apt -y upgrade && apt -y install curl && curl -fsSL https://raw.githubusercontent.com/NemurenaiDesu/reverse-proxy-setup/master/setup.sh | bash -s <destination-ip-address>
```
