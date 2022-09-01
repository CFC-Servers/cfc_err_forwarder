import rawget, rawset, tostring, isfunction, istable from _G

export functionNameCache
functionNameCache or= setmetatable {}, __mode: "k"

defaultSeen = ->
    seen = setmetatable {}, __mode: "k"
    seen[_G] = true
    seen[VFS] = true if VFS
    seen[GLib] = true if GLib
    seen[Gooey] = true if Gooey
    seen[GCompute] = true if GCompute

    return seen

getNamesFrom = (tbl=_G, path="_G", seen=defaultSeen!) ->
    for k, v in pairs tbl
        continue unless isstring k

        if isfunction v
            continue if rawget functionNameCache, v

            newPath = "#{path}.#{k}"
            rawset functionNameCache, v, newPath
            continue

        if istable v
            continue if rawget seen, v
            rawset seen, v, true

            newPath = "#{path}.#{k}"
            getNamesFrom v, newPath, seen

hook.Add "InitPostEntity", "CFC_ErrForwarder_FuncNameSetup", getNamesFrom

(func) ->
    name = functionNameCache[func]
    info = debug.getinfo func, "flLnSu"

    src = info.short_src
    src = string.Replace src, "addons/", ""

    line = "\n"

    if name
        name = string.Replace name, "_G.", ""
        line = "#{line}  #{name}\n"

    line = "#{line}  #{info.short_src}:#{info.linedefined}\n"

    return line
