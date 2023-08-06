# cfc_err_forwarder
A pure-lua (well, Moonscript) Error tracker for Garry's Mod.

This addon will watch for errors, do a little investigation, and send a message to a target Discord channel for your review.

### Some nifty features:
 - :brain: If using source-controlled addons (i.e. git repos in your `addons/` dir), err_forwarder will generate a link to github.com, showing you the exact line that errored
 - :file_cabinet: Tracks Serverside and (optionally) Clientside errors, and can send messages to different channels depending on which realm the errors occurred in
 - :package: Includes configurable batching logic and respects Discord rate limiting, so it won't spam your error channel
 - :mag_right: Shows you the current values of up to 8 local variables in the stack that threw an error (very useful for debugging!)
 - :floppy_disk: Automatically backs up your unsent errors, making it less likely that you lose track of errors if the server crashes/restarts.

## Requirements
 - [gm_logger](https://github.com/CFC-Servers/gm_logger) _(Optional)_
 - [gm_luaerror](https://github.com/danielga/gm_luaerror)
 - [gmsv_reqwest](https://github.com/WilliamVenner/gmsv_reqwest)


## Installation
**Simple**
 - You can download the latest release .zip from the [Releases](https://github.com/CFC-Servers/cfc_err_forwarder/releases) tab. Extract that and place it in your `addons` directory.

**Source Controlled**
 - You can clone this repository directly into your `addons` directory, but be sure to check out the [`lua`](https://github.com/CFC-Servers/cfc_err_forwarder/tree/lua) branch which contains the compiled Lua from the latest release.
 - e.g. ``` git clone --single-branch --branch lua git@github.com:CFC-Servers/cfc_err_forwarder.git ```


## Configuration
 - **`cfc_err_forwarder_dedupe_duration`**: The number of seconds new errors are held before being sent to Discord. Helps de-dupe spammy errors.
 - **`cfc_err_forwarder_backup`**: A boolean indicating whether or not errors should be backed up to a file in case the server crashes or restarts.
 - **`cfc_err_forwarder_server_webhook`**: The full Discord Webhook URL to send Serverside errors
 - **`cfc_err_forwarder_client_webhook`**: The full Discord Webhook URL to send Clientside errors
 - **`cfc_err_forwarder_client_enabled`**: A boolean indicating whether or not the addon should even track Clientside errors


## Screenshots

### Serverside Error with Locals and Context
![DiscordCanary_nmbYDY33PH](https://user-images.githubusercontent.com/7936439/188520510-709cda4d-1f30-4f15-b43a-ac6cddd0723c.png)


### Clientside Error with Context
![image](https://user-images.githubusercontent.com/7936439/188520586-fdd2f05f-c83a-458a-a7f3-8f29fa99b95f.png)
