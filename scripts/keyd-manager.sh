#!/bin/bash
#
# keyd-manager.sh - Install, save, and restore keyd configurations on Fedora
#
# Usage:
#   ./keyd-manager.sh install    - Install keyd via COPR
#   ./keyd-manager.sh save       - Save current keyd config to ~/dotfiles/keyd/
#   ./keyd-manager.sh restore    - Restore keyd config from dotfiles
#   ./keyd-manager.sh status     - Show keyd status and config info
#

set -e

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
KEYD_BACKUP_NAME="keyd"
BACKUP_DIR="$DOTFILES_DIR/$KEYD_BACKUP_NAME"
KEYD_CONFIG_DIR="/etc/keyd"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for certain operations
need_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This operation requires root privileges."
        print_info "Run with: sudo $0 $1"
        exit 1
    fi
}

# Check if keyd is installed
check_keyd_installed() {
    if ! command -v keyd &> /dev/null; then
        return 1
    fi
    return 0
}

# Install keyd
install_keyd() {
    print_info "Installing keyd on Fedora..."
    
    # Check if dnf is available (Fedora)
    if ! command -v dnf &> /dev/null; then
        print_error "dnf not found. This script is designed for Fedora."
        exit 1
    fi
    
    # Enable COPR repository
    print_info "Enabling COPR repository: alternateved/keyd"
    sudo dnf copr enable -y alternateved/keyd
    
    # Install keyd
    print_info "Installing keyd package..."
    sudo dnf install -y keyd
    
    # Verify installation
    if check_keyd_installed; then
        print_success "keyd installed successfully!"
        print_info "Version: $(keyd --version 2>/dev/null || echo 'unknown')"
    else
        print_error "keyd installation failed."
        exit 1
    fi
    
    # Enable and start the service
    print_info "Enabling keyd service..."
    sudo systemctl enable keyd
    sudo systemctl start keyd
    
    print_success "keyd service enabled and started."
    print_info "Configuration directory: $KEYD_CONFIG_DIR"
    print_info "Use 'sudo keyd monitor' to check key events"
}

# Save keyd configuration to dotfiles
save_config() {
    print_info "Saving keyd configuration to dotfiles..."
    
    # Check if keyd config exists
    if [[ ! -d "$KEYD_CONFIG_DIR" ]]; then
        print_error "keyd configuration directory not found: $KEYD_CONFIG_DIR"
        print_info "Make sure keyd is installed first."
        exit 1
    fi
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_warning "Dotfiles directory not found: $DOTFILES_DIR"
        read -p "Create it? [y/N]: " CREATE_DOTFILES
        if [[ "$CREATE_DOTFILES" =~ ^[Yy]$ ]]; then
            mkdir -p "$DOTFILES_DIR"
        else
            print_error "Cannot save without dotfiles directory."
            exit 1
        fi
    fi
    
    # Create backup directory in dotfiles
    mkdir -p "$BACKUP_DIR"
    
    # Create timestamped backup subdirectory
    BACKUP_PATH="$BACKUP_DIR/backups/keyd-backup-$TIMESTAMP"
    mkdir -p "$BACKUP_PATH"
    
    # Copy configuration files
    if [[ -d "$KEYD_CONFIG_DIR" ]]; then
        sudo cp -r "$KEYD_CONFIG_DIR"/* "$BACKUP_PATH/" 2>/dev/null || true
        sudo chown -R $USER:$USER "$BACKUP_PATH"
    fi
    
    # Save additional info
    cat > "$BACKUP_PATH/backup-info.txt" << EOF
Backup Created: $(date)
Keyd Version: $(keyd --version 2>/dev/null || echo 'unknown')
System: $(uname -a)
Original Config Path: $KEYD_CONFIG_DIR
EOF
    
    # Also save to the main dotfiles/keyd directory (current config)
    print_info "Updating current config in $BACKUP_DIR..."
    sudo cp -r "$KEYD_CONFIG_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    sudo chown -R $USER:$USER "$BACKUP_DIR"
    
    # Remove backup-info.txt from main dir if it got copied
    rm -f "$BACKUP_DIR/backup-info.txt" 2>/dev/null || true
    
    # Create/update 'latest' symlink in backups
    ln -sfn "$BACKUP_PATH" "$BACKUP_DIR/backups/latest"
    
    # Count files
    FILE_COUNT=$(find "$BACKUP_PATH" -type f ! -name "backup-info.txt" | wc -l)
    
    print_success "Configuration saved to dotfiles!"
    print_info "Current config: $BACKUP_DIR/"
    print_info "Timestamped backup: $BACKUP_PATH"
    print_info "Files backed up: $FILE_COUNT"
    
    # List backup contents
    if [[ $FILE_COUNT -gt 0 ]]; then
        echo ""
        print_info "Config files in dotfiles:"
        ls -la "$BACKUP_DIR" 2>/dev/null | grep -v "^d" | grep -v "^total" | awk '{print "  " $NF}'
    fi
    
    # Check if dotfiles is a git repo and offer to commit
    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        echo ""
        read -p "Commit changes to git? [y/N]: " DO_COMMIT
        if [[ "$DO_COMMIT" =~ ^[Yy]$ ]]; then
            cd "$DOTFILES_DIR"
            git add "$KEYD_BACKUP_NAME/"
            git commit -m "Update keyd configuration - $TIMESTAMP"
            print_success "Changes committed to dotfiles repo."
        fi
    fi
}

# Restore keyd configuration from dotfiles
restore_config() {
    print_info "Restoring keyd configuration from dotfiles..."
    
    # Check if dotfiles backup exists
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_error "Dotfiles backup not found: $BACKUP_DIR"
        print_info "Save a configuration first using: $0 save"
        exit 1
    fi
    
    # Check for config files in main dotfiles/keyd directory
    CONFIG_FILES=$(find "$BACKUP_DIR" -maxdepth 1 -type f 2>/dev/null)
    
    if [[ -z "$CONFIG_FILES" ]]; then
        # Check for timestamped backups
        if [[ -d "$BACKUP_DIR/backups" ]]; then
            print_info "No current config found. Checking backups..."
            
            # Use 'latest' symlink if it exists
            if [[ -L "$BACKUP_DIR/backups/latest" ]]; then
                RESTORE_PATH="$BACKUP_DIR/backups/latest"
                print_info "Using latest backup: $(readlink -f $BACKUP_DIR/backups/latest)"
            else
                # List available backups
                print_info "Available backups:"
                ls -lt "$BACKUP_DIR/backups" | grep "keyd-backup-" | head -5
                echo ""
                read -p "Enter backup directory name (or press Enter for most recent): " BACKUP_NAME
                
                if [[ -z "$BACKUP_NAME" ]]; then
                    RESTORE_PATH=$(ls -dt "$BACKUP_DIR/backups"/keyd-backup-* 2>/dev/null | head -1)
                else
                    RESTORE_PATH="$BACKUP_DIR/backups/$BACKUP_NAME"
                fi
            fi
        else
            print_error "No configuration files found in dotfiles."
            exit 1
        fi
    else
        # Use main dotfiles/keyd directory
        RESTORE_PATH="$BACKUP_DIR"
    fi
    
    if [[ ! -d "$RESTORE_PATH" ]]; then
        print_error "Backup not found: $RESTORE_PATH"
        exit 1
    fi
    
    # Check for actual config files
    RESTORE_CONFIG_FILES=$(find "$RESTORE_PATH" -type f ! -name "backup-info.txt" 2>/dev/null)
    if [[ -z "$RESTORE_CONFIG_FILES" ]]; then
        print_error "No configuration files found in backup."
        exit 1
    fi
    
    # Create config directory if needed
    sudo mkdir -p "$KEYD_CONFIG_DIR"
    
    # Restore files
    print_info "Restoring from: $RESTORE_PATH"
    sudo cp -r "$RESTORE_PATH"/* "$KEYD_CONFIG_DIR/" 2>/dev/null || true
    
    # Remove backup-info.txt if it got copied to config dir
    sudo rm -f "$KEYD_CONFIG_DIR/backup-info.txt" 2>/dev/null || true
    
    # Show backup info if available
    if [[ -f "$RESTORE_PATH/backup-info.txt" ]]; then
        print_info "Backup details:"
        cat "$RESTORE_PATH/backup-info.txt"
    fi
    
    # Set proper permissions
    sudo chmod 644 "$KEYD_CONFIG_DIR"/*.conf 2>/dev/null || true
    
    print_success "Configuration restored to: $KEYD_CONFIG_DIR"
    
    # Optionally restart keyd if it's running
    if systemctl is-active --quiet keyd; then
        read -p "Restart keyd service now? [y/N]: " RESTART
        if [[ "$RESTART" =~ ^[Yy]$ ]]; then
            sudo systemctl restart keyd
            print_success "keyd service restarted."
        else
            print_info "Remember to restart keyd manually: sudo systemctl restart keyd"
        fi
    else
        print_info "Start keyd with: sudo systemctl start keyd"
    fi
}

# Show status
show_status() {
    echo ""
    echo "========================================="
    echo "           KEYD STATUS"
    echo "========================================="
    echo ""
    
    # Installation status
    if check_keyd_installed; then
        print_success "keyd is installed"
        keyd --version 2>/dev/null || true
        echo ""
        
        # Service status
        if systemctl is-active --quiet keyd; then
            print_success "Service: running"
        else
            print_warning "Service: not running"
        fi
        
        if systemctl is-enabled --quiet keyd; then
            print_info "Service: enabled at boot"
        else
            print_info "Service: not enabled at boot"
        fi
    else
        print_error "keyd is NOT installed"
    fi
    
    echo ""
    
    # Configuration
    echo "--- Configuration ---"
    if [[ -d "$KEYD_CONFIG_DIR" ]]; then
        print_info "Config directory: $KEYD_CONFIG_DIR"
        echo "Config files:"
        sudo ls -la "$KEYD_CONFIG_DIR" 2>/dev/null | tail -n +2 || echo "  (empty or unreadable)"
    else
        print_warning "Config directory not found: $KEYD_CONFIG_DIR"
    fi
    
    echo ""
    
    # Dotfiles backup
    echo "--- Dotfiles Backup ---"
    if [[ -d "$BACKUP_DIR" ]]; then
        print_success "Found: $BACKUP_DIR"
        
        # Current config files
        CURRENT_FILES=$(find "$BACKUP_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
        if [[ $CURRENT_FILES -gt 0 ]]; then
            print_info "Current config files: $CURRENT_FILES"
            ls -la "$BACKUP_DIR" 2>/dev/null | grep -v "^d" | grep -v "^total" | awk '{print "  " $NF}'
        fi
        
        # Timestamped backups
        if [[ -d "$BACKUP_DIR/backups" ]]; then
            BACKUP_COUNT=$(ls -d "$BACKUP_DIR/backups"/keyd-backup-* 2>/dev/null | wc -l)
            print_info "Timestamped backups: $BACKUP_COUNT"
        fi
    else
        print_info "No dotfiles backup found: $BACKUP_DIR"
        print_info "Use '$0 save' to create one."
    fi
    
    echo ""
}

# List backups
list_backups() {
    echo ""
    echo "keyd configuration backups in dotfiles:"
    echo "---------------------------------------"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_info "No backups found. Use '$0 save' to create one."
        return
    fi
    
    # Show current config
    CURRENT_FILES=$(find "$BACKUP_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
    if [[ $CURRENT_FILES -gt 0 ]]; then
        echo "Current config (main):"
        echo "  $BACKUP_DIR/"
        ls -la "$BACKUP_DIR" 2>/dev/null | grep -v "^d" | grep -v "^total" | awk '{print "    " $NF}'
        echo ""
    fi
    
    # Show timestamped backups
    if [[ -d "$BACKUP_DIR/backups" ]]; then
        echo "Timestamped backups:"
        for backup in $(ls -dt "$BACKUP_DIR/backups"/keyd-backup-* 2>/dev/null); do
            BACKUP_NAME=$(basename "$backup")
            if [[ -f "$backup/backup-info.txt" ]]; then
                CREATED=$(grep "Backup Created:" "$backup/backup-info.txt" | cut -d: -f2-)
                echo "  $BACKUP_NAME"
                echo "    Created: $CREATED"
            else
                echo "  $BACKUP_NAME"
            fi
        done
    fi
    
    if [[ $CURRENT_FILES -eq 0 && ! -d "$BACKUP_DIR/backups" ]]; then
        print_info "No configuration files found in backup directory."
    fi
    
    echo ""
}

# Show help
show_help() {
    echo "
keyd-manager.sh - Manage keyd installation and configuration on Fedora

USAGE:
    $0 <command>

COMMANDS:
    install         Install keyd via COPR repository
    save            Save current keyd configuration to ~/dotfiles/keyd/
    restore         Restore keyd configuration from dotfiles
    status          Show keyd status and backup information
    list            List all available backups
    help            Show this help message

EXAMPLES:
    $0 install      # Install keyd
    $0 save         # Save current config to dotfiles
    $0 restore      # Restore from dotfiles
    $0 status       # Check status

FILES:
    System Config:  $KEYD_CONFIG_DIR
    Dotfiles:       $BACKUP_DIR
    Backups:        $BACKUP_DIR/backups/

NOTES:
    - Config is saved to both ~/dotfiles/keyd/ (current) and ~/dotfiles/keyd/backups/ (timestamped)
    - Easy to track changes with git in your dotfiles repo
    - The 'restore' command uses current config or prompts for timestamped backup

For more information about keyd, see: https://github.com/rvaiya/keyd
"
}

# Main command dispatcher
case "${1:-}" in
    install)
        install_keyd
        ;;
    save)
        save_config
        ;;
    restore)
        restore_config
        ;;
    status)
        show_status
        ;;
    list)
        list_backups
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        show_help
        exit 1
        ;;
esac
