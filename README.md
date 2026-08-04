# Overview

This flake hosts my darwin system flake, as well as my nixos servers.

The primary goal of this setup is simple, secure setup of future hosts.

On provisioning, a tagged auth key is passed to enroll a machine in tailscale. On subsequent deployments, the persisted /var/lib/tailscale should provide the tailnet membership to the daemon.