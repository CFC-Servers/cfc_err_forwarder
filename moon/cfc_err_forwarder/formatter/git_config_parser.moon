matchKeyValue = (line) ->
    return string.match line, "^%s+(%w+)%s+=%s+(.*)$"

-- [core]
-- [remote "origin"]
-- [branch "master"]
matchNewSection = (line, struct) ->
    -- core
    -- remote origin
    -- branch master
    line = string.Replace line, "[", ""
    line = string.Replace line, "]", ""
    line = string.Replace line, '"', ""

    -- { "core" }
    -- { "remote", "origin" }
    -- { "branch", "master" }
    spl = string.Split line, " "

    -- "core"
    -- "remote"
    -- "branch"
    main = spl[1]

    -- nil
    -- "origin"
    -- "master"
    sub = spl[2]

    tbl = struct[main] or {}
    tbl[sub] = {} if sub
    struct[main] = tbl

    return tbl[sub] if sub else tbl

(content) ->
    struct = {}

    lines = string.Split content, "\n"
    lineCount = #lines

    local keyvalues
    for i = 1, lineCount
        line = lines[i]

        trim = string.Trim line
        continue if #trim == 0

        char = trim[1]
        continue if char == "#"

        if char == "["
            keyvalues = matchNewSection line, struct
            continue

        key, value = matchKeyValue line
        assert key

        keyvalues[key] = value

    return struct
