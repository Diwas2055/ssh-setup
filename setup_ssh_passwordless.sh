#!/usr/bin/env bash

#############################################################################
# SSH Passwordless Login Setup Script
# 
# Description: Automates the setup of SSH key-based authentication for
#              passwordless login to remote servers.
#
# Usage: ./setup_ssh_passwordless.sh [OPTIONS]
#
# Author: System Administrator
# Version: 1.0.0
#############################################################################

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/ssh_setup_$(date +%Y%m%d_%H%M%S).log"
readonly SSH_DIR="${HOME}/.ssh"
readonly DEFAULT_KEY_TYPE="ed25519"
readonly DEFAULT_KEY_BITS="4096"

#############################################################################
# Logging Functions
#############################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

#############################################################################
# Error Handling
#############################################################################

error_exit() {
    log_error "$1"
    exit 1
}

cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_error "Script failed with exit code: ${exit_code}"
        log_info "Check log file: ${LOG_FILE}"
    fi
}

trap cleanup EXIT

#############################################################################
# Validation Functions
#############################################################################

validate_hostname() {
    local hostname="$1"
    
    if [[ -z "${hostname}" ]]; then
        return 1
    fi
    
    # Basic hostname/IP validation
    if [[ "${hostname}" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+[a-zA-Z0-9]$ ]] || \
       [[ "${hostname}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    
    return 1
}

validate_username() {
    local username="$1"
    
    if [[ -z "${username}" ]]; then
        return 1
    fi
    
    # Basic username validation
    if [[ "${username}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        return 0
    fi
    
    return 1
}

validate_port() {
    local port="$1"
    
    if [[ "${port}" =~ ^[0-9]+$ ]] && [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
        return 0
    fi
    
    return 1
}

#############################################################################
# SSH Functions
#############################################################################

check_ssh_installed() {
    if ! command -v ssh &> /dev/null; then
        error_exit "SSH client is not installed. Please install OpenSSH client."
    fi
    
    if ! command -v ssh-keygen &> /dev/null; then
        error_exit "ssh-keygen is not installed. Please install OpenSSH client."
    fi
    
    if ! command -v ssh-copy-id &> /dev/null; then
        log_warning "ssh-copy-id is not installed. Will use manual key copy method."
        return 1
    fi
    
    return 0
}

create_ssh_directory() {
    if [[ ! -d "${SSH_DIR}" ]]; then
        log_info "Creating SSH directory: ${SSH_DIR}"
        mkdir -p "${SSH_DIR}"
        chmod 700 "${SSH_DIR}"
        log_success "SSH directory created with correct permissions"
    else
        log_info "SSH directory already exists: ${SSH_DIR}"
        # Ensure correct permissions
        chmod 700 "${SSH_DIR}"
    fi
}

generate_ssh_key() {
    local key_type="$1"
    local key_file="$2"
    local key_comment="$3"
    
    log_info "Generating ${key_type} SSH key pair..."
    
    if [[ -f "${key_file}" ]]; then
        log_warning "Key file already exists: ${key_file}"
        read -rp "Do you want to overwrite it? (yes/no): " overwrite
        
        if [[ "${overwrite}" != "yes" ]]; then
            log_info "Using existing key file"
            return 0
        fi
        
        log_warning "Backing up existing key to ${key_file}.bak"
        cp "${key_file}" "${key_file}.bak"
        [[ -f "${key_file}.pub" ]] && cp "${key_file}.pub" "${key_file}.pub.bak"
    fi
    
    case "${key_type}" in
        ed25519)
            ssh-keygen -t ed25519 -C "${key_comment}" -f "${key_file}" -N ""
            ;;
        rsa)
            ssh-keygen -t rsa -b "${DEFAULT_KEY_BITS}" -C "${key_comment}" -f "${key_file}" -N ""
            ;;
        ecdsa)
            ssh-keygen -t ecdsa -b 521 -C "${key_comment}" -f "${key_file}" -N ""
            ;;
        *)
            error_exit "Unsupported key type: ${key_type}"
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        chmod 600 "${key_file}"
        chmod 644 "${key_file}.pub"
        log_success "SSH key pair generated successfully"
        log_info "Private key: ${key_file}"
        log_info "Public key: ${key_file}.pub"
        return 0
    else
        error_exit "Failed to generate SSH key pair"
    fi
}

copy_ssh_key_with_tool() {
    local username="$1"
    local hostname="$2"
    local port="$3"
    local key_file="$4"
    
    log_info "Copying SSH public key to remote server using ssh-copy-id..."
    
    ssh-copy-id -i "${key_file}.pub" -p "${port}" "${username}@${hostname}"
    
    if [[ $? -eq 0 ]]; then
        log_success "SSH key copied successfully using ssh-copy-id"
        return 0
    else
        log_error "Failed to copy SSH key using ssh-copy-id"
        return 1
    fi
}

copy_ssh_key_manual() {
    local username="$1"
    local hostname="$2"
    local port="$3"
    local key_file="$4"
    
    log_info "Copying SSH public key to remote server manually..."
    
    local public_key
    public_key=$(cat "${key_file}.pub")
    
    ssh -p "${port}" "${username}@${hostname}" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '${public_key}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    
    if [[ $? -eq 0 ]]; then
        log_success "SSH key copied successfully (manual method)"
        return 0
    else
        log_error "Failed to copy SSH key manually"
        return 1
    fi
}

test_ssh_connection() {
    local username="$1"
    local hostname="$2"
    local port="$3"
    local key_file="$4"
    
    log_info "Testing SSH connection..."
    
    ssh -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no \
        -i "${key_file}" \
        -p "${port}" \
        "${username}@${hostname}" \
        "echo 'SSH connection successful'" &> /dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "Passwordless SSH login is working!"
        return 0
    else
        log_error "Passwordless SSH login test failed"
        return 1
    fi
}

configure_ssh_config() {
    local hostname="$1"
    local username="$2"
    local port="$3"
    local key_file="$4"
    local alias="$5"
    
    local ssh_config="${SSH_DIR}/config"
    
    log_info "Adding configuration to SSH config file..."
    
    # Create config file if it doesn't exist
    touch "${ssh_config}"
    chmod 600 "${ssh_config}"
    
    # Check if entry already exists
    if grep -q "Host ${alias}" "${ssh_config}"; then
        log_warning "Entry for '${alias}' already exists in SSH config"
        return 0
    fi
    
    # Add new entry
    cat >> "${ssh_config}" << EOF

# Added by setup_ssh_passwordless.sh on $(date)
Host ${alias}
    HostName ${hostname}
    User ${username}
    Port ${port}
    IdentityFile ${key_file}
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF
    
    log_success "SSH config entry added for alias: ${alias}"
    log_info "You can now connect using: ssh ${alias}"
}

#############################################################################
# Main Setup Function
#############################################################################

setup_passwordless_ssh() {
    log_info "Starting SSH passwordless login setup..."
    log_info "Log file: ${LOG_FILE}"
    
    # Check if SSH is installed
    check_ssh_installed
    local has_ssh_copy_id=$?
    
    # Create SSH directory
    create_ssh_directory
    
    # Gather user inputs
    echo ""
    read -rp "Enter remote server hostname/IP: " hostname
    validate_hostname "${hostname}" || error_exit "Invalid hostname/IP address"
    
    read -rp "Enter remote username: " username
    validate_username "${username}" || error_exit "Invalid username"
    
    read -rp "Enter SSH port (default: 22): " port
    port=${port:-22}
    validate_port "${port}" || error_exit "Invalid port number"
    
    read -rp "Enter key type (ed25519/rsa/ecdsa) [default: ed25519]: " key_type
    key_type=${key_type:-${DEFAULT_KEY_TYPE}}
    
    read -rp "Enter SSH alias for config (default: ${hostname}): " alias
    alias=${alias:-${hostname}}
    
    # Set key file path
    local key_file="${SSH_DIR}/id_${key_type}_${alias}"
    local key_comment="${USER}@$(hostname)_${alias}_$(date +%Y%m%d)"
    
    echo ""
    log_info "Configuration Summary:"
    log_info "  Remote Host: ${hostname}"
    log_info "  Remote User: ${username}"
    log_info "  SSH Port: ${port}"
    log_info "  Key Type: ${key_type}"
    log_info "  Key File: ${key_file}"
    log_info "  SSH Alias: ${alias}"
    echo ""
    
    read -rp "Proceed with setup? (yes/no): " proceed
    if [[ "${proceed}" != "yes" ]]; then
        log_info "Setup cancelled by user"
        exit 0
    fi
    
    # Generate SSH key
    generate_ssh_key "${key_type}" "${key_file}" "${key_comment}"
    
    # Copy SSH key to remote server
    echo ""
    log_info "You will be prompted for the remote server password"
    sleep 2
    
    if [[ ${has_ssh_copy_id} -eq 0 ]]; then
        copy_ssh_key_with_tool "${username}" "${hostname}" "${port}" "${key_file}"
    else
        copy_ssh_key_manual "${username}" "${hostname}" "${port}" "${key_file}"
    fi
    
    if [[ $? -ne 0 ]]; then
        error_exit "Failed to copy SSH key to remote server"
    fi
    
    # Test SSH connection
    echo ""
    test_ssh_connection "${username}" "${hostname}" "${port}" "${key_file}"
    
    if [[ $? -ne 0 ]]; then
        log_warning "SSH connection test failed. Please check:"
        log_warning "  1. Remote server allows key-based authentication"
        log_warning "  2. ~/.ssh/authorized_keys has correct permissions (600)"
        log_warning "  3. ~/.ssh directory has correct permissions (700)"
        log_warning "  4. SELinux/AppArmor is not blocking SSH key authentication"
    fi
    
    # Configure SSH config
    echo ""
    read -rp "Add entry to SSH config file? (yes/no): " add_config
    if [[ "${add_config}" == "yes" ]]; then
        configure_ssh_config "${hostname}" "${username}" "${port}" "${key_file}" "${alias}"
    fi
    
    # Summary
    echo ""
    echo "============================================"
    log_success "SSH Passwordless Login Setup Complete!"
    echo "============================================"
    log_info "You can now connect using:"
    log_info "  ssh -i ${key_file} -p ${port} ${username}@${hostname}"
    
    if [[ "${add_config}" == "yes" ]]; then
        log_info "Or simply: ssh ${alias}"
    fi
    
    echo ""
    log_info "Log file saved to: ${LOG_FILE}"
    echo ""
}

#############################################################################
# Display Help
#############################################################################

show_help() {
    cat << EOF
SSH Passwordless Login Setup Script

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -v, --version       Show script version
    -l, --log-file      Specify custom log file location

Description:
    This script automates the setup of SSH key-based authentication
    for passwordless login to remote Linux servers.

Features:
    - Generates SSH key pairs (ed25519, rsa, ecdsa)
    - Copies public key to remote server
    - Tests passwordless connection
    - Configures SSH config file
    - Comprehensive error handling and logging

Examples:
    # Run interactive setup
    $0

    # Run with custom log file
    $0 --log-file /var/log/ssh_setup.log

For more information, visit: https://www.ssh.com/academy/ssh/copy-id

EOF
}

#############################################################################
# Main Script Execution
#############################################################################

main() {
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "SSH Passwordless Setup Script v1.0.0"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    # Run main setup
    setup_passwordless_ssh
}

# Execute main function
main "$@"