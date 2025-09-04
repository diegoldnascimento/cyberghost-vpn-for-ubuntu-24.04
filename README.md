# CyberGhost VPN Low-Latency Connection Script

A Bash script that automatically connects to CyberGhost VPN servers with optimized settings for minimum latency.

## Features

- **Automatic Server Selection**: Finds the US Chicago server with the lowest load percentage
- **System Optimizations**: Applies network kernel parameters for reduced latency
- **CPU Performance Mode**: Sets CPU governor to performance mode when available
- **OpenVPN Configuration**: Uses optimized OpenVPN settings for low-latency connections
- **Connection Verification**: Checks VPN interface, tests latency, and verifies public IP

## Prerequisites

- Linux system with sudo privileges
- CyberGhost VPN subscription and installed client
- OpenVPN installed
- Required directories and files:
  - `/home/$USER/.cyberghost/openvpn/auth` - Authentication credentials
  - `/usr/local/cyberghost/` - CyberGhost installation directory

## Usage

```bash
# Make the script executable
chmod +x vpn.sh

# Run the script (requires sudo)
sudo ./vpn.sh
```

## What the Script Does

1. **System Optimization**
   - Increases network buffer sizes
   - Disables TCP slow start after idle
   - Enables TCP window scaling
   - Sets CPU governor to performance mode

2. **Server Selection**
   - Queries CyberGhost servers in Chicago, US
   - Parses server load percentages
   - Selects the server with lowest load

3. **VPN Connection**
   - Stops any existing CyberGhost VPN services
   - Connects using OpenVPN with optimized parameters:
     - UDP protocol on port 443
     - AES-128-GCM cipher for balance of security and speed
     - Fast I/O mode enabled
     - Zero socket buffers for reduced latency

4. **Connection Verification**
   - Checks if VPN interface (tun0) is active
   - Tests latency to Google DNS (8.8.8.8)
   - Retrieves and displays public IP address

## Configuration

Key parameters that can be modified:

- **Server Location**: Change `--country-code US --city "Chicago"` in line 30
- **Log File**: Default is `/var/log/cyberghost.log`
- **Connection Timeout**: Adjust `sleep 8` in line 93 if needed

## Logs

Connection logs are saved to `/var/log/cyberghost.log`

## Troubleshooting

If the script fails:

1. Ensure CyberGhost VPN is properly installed
2. Check authentication file exists at `~/.cyberghost/openvpn/auth`
3. Verify you have sudo privileges
4. Check the log file for OpenVPN errors

## Security Notes

- The script requires sudo privileges to:
  - Modify system network parameters
  - Start OpenVPN daemon
  - Access CyberGhost certificates
- Authentication credentials are read from a protected file
- Uses TLS server verification for security

## License

This script is provided as-is for personal use with valid CyberGhost VPN subscription.
# cyberghost-vpn-for-ubuntu-24.04