-- https://github.com/CFC-Servers/gm_formdata

local mimeLookup = {
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    png = "image/png",
    gif = "image/gif",
    tif = "image/tiff",
    tiff = "image/tiff",
    bmp = "image/bmp",
    ico = "image/x-icon",
    txt = "text/plain",
    html = "text/html",
    htm = "text/html",
    css = "text/css",
    js = "application/javascript",
    json = "application/json",
    xml = "application/xml",
    pdf = "application/pdf",
    zip = "application/zip",
    rar = "application/x-rar-compressed",
    gz = "application/x-gzip",
    tar = "application/x-tar",
    mp3 = "audio/mpeg",
    wav = "audio/wav",
    ogg = "audio/ogg",
    mp4 = "video/mp4",
    webm = "video/webm",
    mkv = "video/x-matroska",
    avi = "video/x-msvideo",
    mov = "video/quicktime",
    wmv = "video/x-ms-wmv",
    flv = "video/x-flv",
    swf = "application/x-shockwave-flash",
    svg = "image/svg+xml",
    svgz = "image/svg+xml",
    eot = "application/vnd.ms-fontobject",
    ttf = "application/font-sfnt",
    woff = "application/font-woff",
    woff2 = "application/font-woff2",
    otf = "application/font-sfnt",
}

local function getMimeType( filename )
    local ext = string.GetExtensionFromFilename( filename )
    return mimeLookup[string.lower( ext )] or "application/octet-stream"
end

function FormData()
    return {
        entries = {},
        boundary = tostring( math.Round( os.time() ) ),

        Append = function( self, name, value, mime, filename )
            if mime and not filename then
                -- Gotta figure out what our params are
                local isMime = string.find( mime, "/", 1, false ) ~= nil

                if not isMime then
                    -- mime is actually the filename
                    filename = mime
                    mime = getMimeType( filename )
                end
            end

            if not mime and istable( value ) then
                value = util.TableToJSON( value )
                mime = "application/json"
            end

            table.insert( self.entries, {
                name = name,
                value = value,
                mime = mime,
                filename = filename
            } )
        end,

        Read = function( self )
            local body = ""

            for _, entry in ipairs( self.entries ) do
                local mime = entry.mime
                local name = entry.name
                local value = entry.value
                local filename = entry.filename

                body = body .. "--" .. self.boundary
                body = body .. "\r\nContent-Disposition: form-data; name=\"" .. name .. "\""
                if filename then
                    body = body .. "; filename=\"" .. filename .. "\""
                end

                body = body .. "\r\nContent-Type: " .. ( mime or "text/plain" ) .. "; charset=utf-8"
                body = body .. "\r\n\r\n" .. value .. "\r\n"
            end

            body = body .. "--" .. self.boundary .. "--\r\n"

            return body
        end,

        GetHeaders = function( self )
            return {
                ["Content-Length"] = #self:Read(),
                ["Content-Type"] = "multipart/form-data; charset=utf-8; boundary=" .. self.boundary
            }
        end
    }
end

