# SSH Passwordless Login Setup Script

A comprehensive bash script for automating SSH key-based authentication setup, enabling secure passwordless login to remote Linux servers.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Advanced Usage](#advanced-usage)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This script automates the entire process of setting up SSH key-based authentication, eliminating the need to manually:

- Generate SSH key pairs
- Copy public keys to remote servers
- Configure SSH client settings
- Test passwordless connections

Perfect for system administrators, DevOps engineers, and anyone who frequently connects to remote servers.

## ✨ Features

### Core Functionality
- ✅ **Multiple Key Types**: Support for ed25519 (recommended), RSA, and ECDSA
- ✅ **Automated Key Generation**: Creates secure SSH key pairs with proper permissions
- ✅ **Smart Key Deployment**: Uses `ssh-copy-id` when available, falls back to manual method
- ✅ **Connection Testing**: Verifies passwordless authentication works before completion
- ✅ **SSH Config Integration**: Optionally adds convenient aliases to `~/.ssh/config`

### Quality & Reliability
- 🛡️ **Robust Error Handling**: Comprehensive validation and error recovery
- 📝 **Detailed Logging**: Timestamped logs for troubleshooting and auditing
- 🎨 **Colorized Output**: Easy-to-read status messages with color coding
- 🔒 **Security First**: Follows SSH best practices and security guidelines
- 💾 **Backup Protection**: Automatically backs up existing keys before overwriting

### User Experience
- 🚀 **Interactive Setup**: User-friendly prompts with sensible defaults
- 📊 **Configuration Summary**: Review settings before proceeding
- ✅ **Validation**: Input validation for hostnames, usernames, and ports
- 📖 **Help Documentation**: Built-in help and usage information

## 📦 Prerequisites

### Required
- **Operating System**: Linux, macOS, or WSL2 on Windows
- **OpenSSH Client**: Version 7.0 or higher
- **Bash**: Version 4.0 or higher
- **Network Access**: Ability to connect to remote server via SSH

### Optional
- `ssh-copy-id` utility (recommended for easier key deployment)
- Write access to `~/.ssh/config` for alias configuration

### Check Prerequisites

```bash
# Check SSH client version
ssh -V

# Check bash version
bash --version

# Check if ssh-copy-id is available
which ssh-copy-id

# Verify network connectivity
ping -c 3 your-remote-server.com
```

## 🚀 Installation

### Quick Install

```bash
# Download the script
curl -O https://raw.githubusercontent.com/Diwas2055/ssh-setup/main/setup_ssh_passwordless.sh

# Make it executable
chmod +x setup_ssh_passwordless.sh

# Run the script
./setup_ssh_passwordless.sh
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/Diwas2055/ssh-setup.git
cd ssh-setup

# Make script executable
chmod +x setup_ssh_passwordless.sh

# Optionally, add to PATH
sudo cp setup_ssh_passwordless.sh /usr/local/bin/ssh-setup
```

## 💻 Usage

### Basic Usage

```bash
# Run interactive setup
./setup_ssh_passwordless.sh
```

### Command-Line Options

```bash
# Display help information
./setup_ssh_passwordless.sh --help

# Show version information
./setup_ssh_passwordless.sh --version
```

### Interactive Setup Example

```
$ ./setup_ssh_passwordless.sh

[INFO] Starting SSH passwordless login setup...
[INFO] Log file: /home/user/ssh_setup_20260116_143022.log

Enter remote server hostname/IP: webserver.example.com
Enter remote username: admin
Enter SSH port (default: 22): 22
Enter key type (ed25519/rsa/ecdsa) [default: ed25519]: ed25519
Enter SSH alias for config (default: webserver.example.com): webserver

[INFO] Configuration Summary:
  Remote Host: webserver.example.com
  Remote User: admin
  SSH Port: 22
  Key Type: ed25519
  Key File: /home/user/.ssh/id_ed25519_webserver
  SSH Alias: webserver

Proceed with setup? (yes/no): yes

[INFO] Generating ed25519 SSH key pair...
[SUCCESS] SSH key pair generated successfully

[INFO] You will be prompted for the remote server password
[INFO] Copying SSH public key to remote server using ssh-copy-id...
admin@webserver.example.com's password: 

[SUCCESS] SSH key copied successfully using ssh-copy-id

[INFO] Testing SSH connection...
[SUCCESS] Passwordless SSH login is working!

Add entry to SSH config file? (yes/no): yes
[SUCCESS] SSH config entry added for alias: webserver

============================================
[SUCCESS] SSH Passwordless Login Setup Complete!
============================================
[INFO] You can now connect using:
  ssh -i /home/user/.ssh/id_ed25519_webserver -p 22 admin@webserver.example.com
Or simply: ssh webserver

[INFO] Log file saved to: /home/user/ssh_setup_20260116_143022.log
```

## ⚙️ Configuration

### SSH Key Types

The script supports three key types:

#### ed25519 (Recommended)
- **Pros**: Fastest, most secure, smallest key size
- **Cons**: Not supported on very old SSH implementations
- **Use When**: Default choice for modern systems

```bash
# Selected by default
Enter key type: ed25519
```

#### RSA
- **Pros**: Universal compatibility, well-established
- **Cons**: Larger key size, slower than ed25519
- **Use When**: Maximum compatibility needed

```bash
# 4096-bit RSA keys generated
Enter key type: rsa
```

#### ECDSA
- **Pros**: Good performance, smaller than RSA
- **Cons**: Less common, potential patent concerns
- **Use When**: Balance between compatibility and performance

```bash
# 521-bit ECDSA keys generated
Enter key type: ecdsa
```

### SSH Config File

When you choose to add an entry to `~/.ssh/config`, the script creates a configuration like:

```
Host webserver
    HostName webserver.example.com
    User admin
    Port 22
    IdentityFile /home/user/.ssh/id_ed25519_webserver
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

This allows you to connect using simply:
```bash
ssh webserver
```

### File Locations

```
~/.ssh/                           # SSH directory (700 permissions)
├── id_ed25519_webserver          # Private key (600 permissions)
├── id_ed25519_webserver.pub      # Public key (644 permissions)
├── config                        # SSH client configuration (600 permissions)
└── authorized_keys               # On remote server (600 permissions)
```

### Log Files

Logs are saved in the script directory with timestamps:
```
ssh_setup_YYYYMMDD_HHMMSS.log
```

Example: `ssh_setup_20260116_143022.log`

## 🔧 Troubleshooting

### Common Issues

#### 1. Permission Denied (publickey)

**Problem**: SSH connection fails with "Permission denied (publickey)" error.

**Solutions**:
```bash
# Check local private key permissions
chmod 600 ~/.ssh/id_ed25519_webserver

# Check remote authorized_keys permissions
ssh user@host "chmod 600 ~/.ssh/authorized_keys"

# Check remote .ssh directory permissions
ssh user@host "chmod 700 ~/.ssh"

# Verify key was added to authorized_keys
ssh user@host "cat ~/.ssh/authorized_keys"
```

#### 2. Host Key Verification Failed

**Problem**: SSH warns about host key changes.

**Solutions**:
```bash
# Remove old host key
ssh-keygen -R hostname

# Or remove all host keys for the IP
ssh-keygen -R 192.168.1.100
```

#### 3. SSH Agent Issues

**Problem**: Keys not being used even though they exist.

**Solutions**:
```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add your key to the agent
ssh-add ~/.ssh/id_ed25519_webserver

# List loaded keys
ssh-add -l
```

#### 4. SELinux/AppArmor Blocking

**Problem**: Keys work but connection still asks for password on SELinux systems.

**Solutions**:
```bash
# On remote server (RHEL/CentOS/Fedora)
restorecon -R -v ~/.ssh

# Check SELinux status
getenforce

# Temporarily disable for testing (not recommended for production)
sudo setenforce 0
```

#### 5. Key Already Exists

**Problem**: Script finds existing key file.

**Options**:
- Choose "yes" to overwrite (old key backed up to `.bak`)
- Choose "no" to use existing key
- Manually specify different key name

### Debug Mode

Enable verbose SSH output for troubleshooting:

```bash
# Test connection with verbose output
ssh -vvv -i ~/.ssh/id_ed25519_webserver user@host

# Check what's happening during authentication
ssh -vvv user@host 2>&1 | grep -i "auth"
```

### Remote Server Requirements

Verify remote server SSH configuration:

```bash
# On remote server, check sshd_config
sudo grep -i "PubkeyAuthentication" /etc/ssh/sshd_config
# Should show: PubkeyAuthentication yes

sudo grep -i "PasswordAuthentication" /etc/ssh/sshd_config
# Can be yes or no (yes needed for initial setup)

# Restart SSH service after changes
sudo systemctl restart sshd  # or ssh on Ubuntu
```

## 🔒 Security Considerations

### Best Practices

1. **Use Strong Key Types**
   - Prefer ed25519 for new keys
   - Minimum 4096 bits for RSA keys
   - Never use DSA keys (deprecated)

2. **Protect Private Keys**
   - Never share private keys
   - Keep private keys on local machine only
   - Use passphrase protection for high-security environments
   - Store securely with appropriate file permissions (600)

3. **Limit Key Usage**
   - Use different keys for different servers/purposes
   - Rotate keys periodically
   - Remove old keys from authorized_keys

4. **Server Hardening**
   ```bash
   # On remote server, edit /etc/ssh/sshd_config
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes
   AuthorizedKeysFile .ssh/authorized_keys
   ```

5. **Audit and Monitor**
   - Review authorized_keys regularly
   - Monitor SSH logs: `tail -f /var/log/auth.log`
   - Use fail2ban to prevent brute force attacks

### Adding Passphrase to Existing Keys

If you want to add passphrase protection to keys created by the script:

```bash
# Add passphrase to existing key
ssh-keygen -p -f ~/.ssh/id_ed25519_webserver

# Use ssh-agent to avoid typing passphrase repeatedly
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_webserver
```

### Key Management

```bash
# List all SSH keys
ls -la ~/.ssh/id_*

# Remove a key pair
rm ~/.ssh/id_ed25519_webserver{,.pub}

# Remove key from remote server
ssh user@host "sed -i '/webserver/d' ~/.ssh/authorized_keys"
```

## 🎓 Advanced Usage

### Multiple Keys for Different Servers

The script supports creating unique keys for each server:

```bash
# Run script multiple times with different aliases
./setup_ssh_passwordless.sh
# First time: alias = server1
./setup_ssh_passwordless.sh
# Second time: alias = server2
```

Result in `~/.ssh/config`:
```
Host server1
    HostName 192.168.1.10
    IdentityFile ~/.ssh/id_ed25519_server1

Host server2
    HostName 192.168.1.20
    IdentityFile ~/.ssh/id_ed25519_server2
```

### Jump Hosts / Bastion Servers

After initial setup, configure jump hosts in `~/.ssh/config`:

```
Host production-server
    HostName 10.0.1.100
    User admin
    IdentityFile ~/.ssh/id_ed25519_prod
    ProxyJump bastion

Host bastion
    HostName bastion.example.com
    User jumpuser
    IdentityFile ~/.ssh/id_ed25519_bastion
```

### Automation Scripts

Use the script in automation workflows:

```bash
#!/bin/bash
# Deploy keys to multiple servers

SERVERS=("web1" "web2" "db1")

for server in "${SERVERS[@]}"; do
    echo "Setting up $server..."
    # You'll need to handle inputs programmatically
    # or pre-configure SSH keys manually
done
```

### Port Forwarding Setup

After passwordless login is set up:

```bash
# Local port forwarding
ssh -L 8080:localhost:80 webserver

# Remote port forwarding
ssh -R 9000:localhost:3000 webserver

# Dynamic port forwarding (SOCKS proxy)
ssh -D 1080 webserver
```

### Using with Ansible

After setup, use in Ansible inventory:

```ini
[webservers]
webserver ansible_host=webserver.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/id_ed25519_webserver
```

### Certificate-based Authentication

For advanced scenarios, transition to SSH certificates:

```bash
# Generate certificate authority key
ssh-keygen -t ed25519 -f ~/.ssh/ca_user_key

# Sign user key with CA
ssh-keygen -s ~/.ssh/ca_user_key -I user_id -n username -V +52w ~/.ssh/id_ed25519_webserver.pub
```

## ❓ FAQ

### Q: Can I use this script on Windows?

**A:** Yes, but you need WSL2 (Windows Subsystem for Linux) or Git Bash. PowerShell users should use native PowerShell SSH tools.

### Q: Is it safe to disable password authentication?

**A:** Yes, after verifying key-based authentication works. It's actually more secure than passwords. Always test thoroughly first and keep a backup access method.

### Q: How do I connect from multiple computers?

**A:** Either:
1. Generate separate keys on each computer and add all to `authorized_keys`
2. Securely copy your private key (not recommended for high-security environments)

### Q: What if I lose my private key?

**A:** You'll need password access or console access to the server to set up a new key. This is why backup access methods are important.

### Q: Can I use the same key for multiple servers?

**A:** Yes, you can add the same public key to multiple servers' `authorized_keys` files. However, using separate keys per server is more secure.

### Q: How do I revoke access?

**A:** Remove the corresponding public key entry from `~/.ssh/authorized_keys` on the remote server.

### Q: Does this work with GitHub/GitLab?

**A:** Yes! Use the same public key format. Add your public key to GitHub/GitLab settings.

```bash
# Copy public key to clipboard (Linux)
xclip -selection clipboard < ~/.ssh/id_ed25519_webserver.pub

# macOS
pbcopy < ~/.ssh/id_ed25519_webserver.pub
```

### Q: How often should I rotate SSH keys?

**A:** Best practice: annually or when employees leave. High-security environments: quarterly.

### Q: Can I use this for root access?

**A:** Technically yes, but it's not recommended. Use a regular user with sudo privileges instead.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/Diwas2055/ssh-setup.git
cd ssh-setup

# Make changes and test
./setup_ssh_passwordless.sh --help
```

### Coding Standards

- Follow bash best practices
- Use shellcheck for linting
- Add comments for complex logic
- Update README for new features

### Testing

```bash
# Lint the script
shellcheck setup_ssh_passwordless.sh

# Test in different environments
docker run -it ubuntu:22.04 bash
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- OpenSSH team for the excellent SSH implementation
- The Linux/Unix community for best practices and security guidelines
- Contributors and users who provide feedback and improvements

##  Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [SSH Academy](https://www.ssh.com/academy/ssh)
- [DigitalOcean SSH Tutorial](https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys)
- [GitHub SSH Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

---