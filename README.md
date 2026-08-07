# Overview

This flake hosts my darwin system flake, as well as my nixos servers.

The primary goal of this setup is simple, secure setup of future hosts.

On provisioning, a tagged auth key is passed to enroll a machine in tailscale. On subsequent deployments, the persisted /var/lib/tailscale should provide the tailnet membership to the daemon. The file will still be pointed to in the module, requiring the file to be present for the system activation script. Key file will be cleared instead of deleted/shredded.

Designed with an ephemeral root setup. Reprovisioning a system shouldn't affect it (excluding storage drive for now (may consider some backup or method to persist between provisioning))

If feasible, I'd like to automate sops on provision as well. Likely just printing public key to the provisioner console to place in sops.yaml for re-encryption. I don't yet have sops secrets in place. Need to consider potential issues on hosts trying to decrypt secrets on provisioning, once the secrets are declared in flake.

