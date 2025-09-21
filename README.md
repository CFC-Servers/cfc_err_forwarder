# CFC Error Forwarder
<p align="left">
    <a href="https://discord.gg/5JUqZjzmYJ" alt="Discord Invite"><img src="https://img.shields.io/discord/981394195812085770?label=Support&logo=discord&logoColor=white" /></a>
</p>

![Downloads](https://img.shields.io/github/downloads/CFC-Servers/cfc_err_forwarder/total)

A powerful, pure-Lua error tracking and reporting system for Garry's Mod servers. This addon monitors both server and client-side errors, performs detailed analysis, and delivers comprehensive reports directly to your Discord channel.

## 🚀 Features

- **📍 Smart Source Integration**: Automatically generates links to the exact error location in your GitHub repositories
- **🔄 Dual-Realm Support**: Tracks both serverside and clientside errors with separate Discord channel configuration
- **📦 Intelligent Batching**: Configurable error batching and rate limiting to prevent channel spam
- **💾 Error Persistence**: Automatically backs up unsent errors to prevent data loss during server crashes or restarts

## 📋 Requirements

- **[gmsv_reqwest](https://github.com/WilliamVenner/gmsv_reqwest)**: Required for sending messages to Discord

## ⚙️ Configuration

| ConVar | Description | Default |
|--------|-------------|---------|
| `cfc_err_forwarder_interval` | Time interval (in seconds) to send error reports | `60` |
| `cfc_err_forwarder_backup` | Enable error backup to prevent loss on crash/restart | `true` |
| `cfc_err_forwarder_server_webhook` | Discord webhook URL for serverside errors | `""` |
| `cfc_err_forwarder_client_webhook` | Discord webhook URL for clientside errors | `""` |
| `cfc_err_forwarder_client_enabled` | Enable tracking of clientside errors | `true` |

## 📊 Examples

### Serverside Error with Locals and Context
![Serverside Error Example](https://github.com/user-attachments/assets/f694166e-34d1-4e69-9782-711c8c04294e)

### Clientside Error with Context
![Clientside Error Example](https://github.com/user-attachments/assets/10bc91f6-6581-4949-8027-292466ed9146)


## 🤝 Contributing

Contributions are welcome! Feel free to submit pull requests or open issues on our [GitHub repository](https://github.com/CFC-Servers/cfc_err_forwarder).

---

© CFC Servers - Made with ❤️ for the Garry's Mod community

