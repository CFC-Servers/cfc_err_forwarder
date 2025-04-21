local EF = ErrorForwarder

--- @type table<string, Color>
EF.colors = {
    error = Color( 255, 16, 83, 255 ),
    info = Color( 108, 110, 160, 255 ),
    warn = Color( 255, 165, 0, 255 ),
    debug = Color( 0, 191, 255, 255 ),
    highlight = Color( 102, 199, 244, 255 ),
    background = Color( 193, 202, 214, 255 ),
}
local colors = EF.colors

--- @class ErrorForwarderLogger
EF.Logger = {}
local Logger = EF.Logger

local function prefix( color, ... )
    return colors.background, "[", color, "ErrorForwarder", colors.background, "] ", color, ...
end

local debugCol = colors.debug
function Logger.debug( ... )
    MsgC( prefix( debugCol, ... ) )
    MsgN()
end

local infoCol = colors.info
function Logger.info( ... )
    MsgC( prefix( infoCol, ... ) )
    MsgN()
end

local warnCol = colors.warn
function Logger.warn( ... )
    MsgC( prefix( warnCol, ... ) )
    MsgN()
end

local errCol = colors.error
function Logger.err( ... )
    MsgC( prefix( errCol, ... ) )
    MsgN()
end
