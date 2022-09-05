# cfc_err_forwarder
I forward errors, it's what I do.


## Requirements
 - [gm_logger](https://github.com/CFC-Servers/gm_logger)
 - [gm_luaerror](https://github.com/danielga/gm_luaerror)
 - [gmsv_reqwest](https://github.com/WilliamVenner/gmsv_reqwest)


## Installation
**Simple**
 - You can download the latest release .zip from the [Releases](https://github.com/CFC-Servers/cfc_err_forwarder/releases) tab. Extract that and place it in your `addons` directory.

**Source Controlled**
 - You can clone this repository directly into your `addons` directory, but be sure to check out the [`lua`](https://github.com/CFC-Servers/cfc_err_forwarder/tree/lua) branch which contains the compiled Lua from the latest release.
 - e.g. ``` git clone --single-branch --branch lua git@github.com:CFC-Servers/cfc_err_forwarder.git ```


## Configuration
 - **`cfc_err_forwarder_interval`**: The interval (in seconds) at which errors are parsed and sent to Discord
 - **`cfc_err_forwarder_server_webhook`**: The full Discord Webhook URL to send Serverside errors
 - **`cfc_err_forwarder_client_webhook`**: The full Discord Webhook URL to send Clientside errors
 - **`cfc_err_forwarder_client_enabled`**: A boolean indicating whether or not the addon should even track Clientside errors


## Screenshots

### Serverside Error with Locals and Context
![DiscordCanary_nmbYDY33PH](https://user-images.githubusercontent.com/7936439/188520510-709cda4d-1f30-4f15-b43a-ac6cddd0723c.png)


### Clientside Error with Context
![image](https://user-images.githubusercontent.com/7936439/188520586-fdd2f05f-c83a-458a-a7f3-8f29fa99b95f.png)
