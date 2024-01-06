# cfc_err_forwarder
A pure-lua (well, Moonscript) Error tracker for Garry's Mod.

This addon will watch for errors, do a little investigation, and send a message to a Discord channel for your review.

<br>

## Notice ⚠️
A full-rewrite of this addon is nearly complete. It has fixes, new features, design reworks, and will attempt to use the upcoming [`OnLuaError`](https://wiki.facepunch.com/gmod/GM:OnLuaError) hook.

Please keep an eye out for the update!

You can track its progress in our support Discord: https://discord.gg/5JUqZjzmYJ

<br>

### Some nifty features:
 - 🧠 If using source-controlled addons (i.e. git repos in your `addons/` dir), err_forwarder will generate a link to github.com, showing you the exact line that errored
 - 🪝 Tracks Serverside and (optionally) Clientside errors, and can send messages to different channels depending on which realm the errors occurred in
 - 📦 Includes basic batching logic so it won't spam your error channel
 - 🔎 Shows you the current values of up to 8 local variables in the stack that threw an error (very useful for debugging!)

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
 - **`cfc_err_forwarder_interval`**: The interval (in seconds) at which errors are parsed and sent to Discord
 - **`cfc_err_forwarder_server_webhook`**: The full Discord Webhook URL to send Serverside errors
 - **`cfc_err_forwarder_client_webhook`**: The full Discord Webhook URL to send Clientside errors
 - **`cfc_err_forwarder_client_enabled`**: A boolean indicating whether or not the addon should even track Clientside errors

## Hooks

### `CFC_ErrorForwarder_PreQueue`
Called before an Error is queued to be processed. 

Return `false` to prevent it from being queued.

You may also _(carefully)_ modify the error structure.

### Error Structure
With the following code:
```lua
-- addons/example/lua/example/init.lua
AddCSLuaFile()
if SERVER then return end

local function exampleFunction()
    print( 5 + {} )
end

hook.Add( "InitPostEntity", "Example", function()
    ProtectedCall( exampleFunction )
end )
```

The error structure would look like:
| **Name**         | **Type**  | **Example**                                                          | **Description**                                                                                                                                                         |
|------------------|-----------|----------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `branch`         | `string`  | `"unknown"` _(Base branch)_                                          | The game branch where the error occurred. Is either `"Not sure yet"` if the client errored early, or [`BRANCH`](https://wiki.facepunch.com/gmod/Global.BRANCH) string   |
| `count`          | `number`  | `1`                                                                  | How many times this error has occurred _(Will always be `1` in `CFC_ErrorForrwarder_PreQueue`)_                                                                         |
| `errorString`    | `string`  | `"attempt to perform arithmetic on a table value"`                   | The actual error message that was produced                                                                                                                              |
| `fullError`      | `string`  |                                                                      | The full, raw, multiline error string with a simplified stack                                                                                                           |
| `isClientside`   | `boolean` | `true`                                                               | Whether or not this error occurred on a client                                                                                                                          |
| `isRuntime`      | `boolean` | `true`                                                               | "Whether this is a runtime error or not" - taken straight from `gm_luaerror`                                                                                            |
| `occurredAt`     | `number`  | `1704534832`                                                         | The result of `os.time()` of when the error occurred                                                                                                                    |
| `ply`            | `Player`  | `Player [1][Phatso]`                                                 | The Player who experienced the error, or `nil` if serverside                                                                                                            |
| `plyName`        | `string`  | `"Phatso"`                                                           | `nil` if serverside                                                                                                                                                     |
| `plySteamID`     | `string`  | `"STEAM_0:0:21170873"`                                               | `nil` if serverside                                                                                                                                                     |
| `reportInterval` | `number`  | `60`                                                                 | In seconds, how often the addon is sending errors to Discord                                                                                                            |
| `sourceFile`     | `string`  | `"addons/test/lua/example/init.lua"`                                 | The file path where the error occurred                                                                                                                                  |
| `sourceLine`     | `number`  | `4`                                                                  |                                                                                                                                                                         |
| `stack`          | `table`   | `{ 1 = { currentLine = 4, name = "unknown", source = "..." }, ... }` | A numerically indexed Stack object                                                                                                                                      |


## Screenshots

### Serverside Error with Locals and Context
![DiscordCanary_nmbYDY33PH](https://user-images.githubusercontent.com/7936439/188520510-709cda4d-1f30-4f15-b43a-ac6cddd0723c.png)


### Clientside Error with Context
![image](https://user-images.githubusercontent.com/7936439/188520586-fdd2f05f-c83a-458a-a7f3-8f29fa99b95f.png)
