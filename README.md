# cfc_err_forwarder
A pure-lua Error tracker for Garry's Mod.

This addon will watch for errors, do a little investigation, and send a message to a target Discord channel for your review.

### Some nifty features:
 - :brain: If using source-controlled addons (i.e. git repos in your `addons/` dir), err_forwarder will generate a link to github.com, showing you the exact line that errored
 - :file_cabinet: Tracks Serverside and (optionally) Clientside errors, and can send messages to different channels depending on which realm the errors occurred in
 - :package: Includes configurable batching logic and respects Discord rate limiting, so it won't spam your error channel
 - :mag_right: Shows you the current values of up to 8 local variables in the stack that threw an error (very useful for debugging!)
 - :floppy_disk: Automatically backs up your unsent errors, making it less likely that you lose track of errors if the server crashes/restarts.

## Requirements
 - [gm_luaerror](https://github.com/danielga/gm_luaerror) _(**OPTIONAL**)_
  - This binary enhances the error messages sent to Discord with a lot of extra context, including the full stack trace and local variables.
  - It also allows us to catch Clientside errors, which is not possible with the default Lua error handler.
 - [gmsv_reqwest](https://github.com/WilliamVenner/gmsv_reqwest) _(for sending the Discord messages)_


## Configuration
 - **`cfc_err_forwarder_dedupe_duration`**: The number of seconds new errors are held before being sent to Discord. Helps de-dupe spammy errors.
 - **`cfc_err_forwarder_backup`**: A boolean indicating whether or not errors should be backed up to a file in case the server crashes or restarts.
 - **`cfc_err_forwarder_server_webhook`**: The full Discord Webhook URL to send Serverside errors
 - **`cfc_err_forwarder_client_webhook`**: The full Discord Webhook URL to send Clientside errors
 - **`cfc_err_forwarder_client_enabled`**: A boolean indicating whether or not the addon should even track Clientside errors
 - **`cfc_err_forwarder_include_full_context`**: A boolean indicating whether or not the full error context should be included in the Discord messsages _(Only relevant for gm_luaerror)_
 - **`cfc_err_forwarder_enable_name_cache`**: A boolean indicating whether or not to build a full "Pretty name" cache for all functions in _G. This can impact startup time. (Only relevant for gm_luaerror)


## Screenshots

### Serverside Error with Locals and Context
![image](https://github.com/user-attachments/assets/f694166e-34d1-4e69-9782-711c8c04294e)

### Clientside Error with Context
![image](https://github.com/user-attachments/assets/10bc91f6-6581-4949-8027-292466ed9146)

