# cfc_err_forwarder
I forward errors, it's what I do.


## Requirements
 - [gm_logger](https://github.com/CFC-Servers/gm_logger)
 - [gm_luaerror](https://github.com/danielga/gm_luaerror)
 - [gmsv_reqwest](https://github.com/WilliamVenner/gmsv_reqwest)


## Configuration
 - **`cfc_err_forwarder_server_webhook`**: The full Discord Webhook URL (after the `https://`) to send Serverside errors
 - **`cfc_err_forwarder_client_webhook`**: The full Discord Webhook URL (after the `https://`) to send Clientside errors
 - **`cfc_err_forwarder_client_enabled`**: A boolean indicating whether or not the addon should even track Clientside errors
