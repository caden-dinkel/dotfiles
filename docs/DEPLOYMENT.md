# Architectural Decision Record (ADR): Security for NixOS Infrastructure

## System Deployment

### Deploy-rs 

`deploy-rs` is an SSH-based deployment tool designed for NixOS multi-system flakes. It connects to target nodes, builds or pushes configurations, and activates them.

Because `deploy-rs` triggers remote system activation—which can fundamentally alter or replace the operating system state—securing the remote execution path is critical. Any unauthorized access to the deployment mechanism results in full remote code execution (RCE) over the target infrastructure.

#### Target User Privileges

Because deploy-rs triggers remote system activation—which can fundamentally alter or replace the operating system state—securing the remote execution path is critical. Any unauthorized access to the deployment mechanism results in full remote code execution (RCE) over the target infrastructure.

##### Option A: The Root User

Description: Connecting directly as the root user via SSH (restricted by SSH key authentication).

- Pros:
 - Simplicity: Minimal configuration overhead; root inherently possesses all necessary permissions to manipulate system profiles.

- Cons:
 - Expanded Attack Surface: Exposes a direct remote login path for the root account across the network.
 - Violation of Least Privilege: If the deployment credentials or automation pipeline are compromised, the attacker instantly gains unrestricted root access to the machine.

##### Option B: Dedicated Least-Privilege Deploy User

Description: Creating a non-privileged user (e.g., deployer) granted passwordless execution rights (NOPASSWD) via sudo limited strictly to the commands required by deploy-rs.

- Pros:
 - Isolation: Eliminates direct remote SSH login for the root user.
 - Reduced Blast Radius: Even though an exploit of the deployment user is still high-severity, it separates standard system administration from automated configuration pipelines.

- Cons:
 - Configuration Complexity: Requires managing specialized sudoers rules and ensuring the user environment matches deploy-rs expectations.

#### Network Topologies & Access Control

Securing how deploy-rs reaches the target nodes involves balancing network exposure with administrative overhead.

##### Option A: Public Internet / Routed LAN

Description: Exposing the standard SSH port (port 22) to the general internet (or a wide local network), secured primarily via SSH key pairs.

- Pros:
 - Ease of Setup: Straightforward to configure and works universally across any standard hosting provider.
 - Decoupled: Does not rely on third-party overlay networks.

- Cons:
 - Increased Vulnerability Exposure: Publicly facing SSH ports are constantly targeted by brute-force attacks and automated bots.
 - Hardened Setup Required: Securing this approach properly demands additional measures like port knocking, fail2ban, or strict IP whitelisting, which increases architectural complexity.

##### Option B: Overlay Network / VPN (Tailscale or WireGuard)

Description: Restricting SSH access so that connections can only be established over a private, encrypted overlay network (such as Tailscale or a dedicated WireGuard mesh).

- Pros:
 - Defense in Depth: Access requires both a valid SSH key and membership in the private identity network. Public-facing ports can be closed entirely at the firewall level.
 - Simplified Target Routing: Tools like deploy-rs can target nodes securely using their stable internal VPN IP addresses. (Note: WireGuard handles this natively via point-to-point IP routing, requiring no centralized control plane beyond initial peer configuration, whereas Tailscale provides built-in access control lists and a managed control plane).

- Cons:
 - Operational Dependency: Introduces a dependency on the overlay network remaining healthy for infrastructure deployments to succeed.
 - Setup Overhead: Requires initial bootstrapping of the mesh network on every new host.
