(data) ->
    -- Start at -1 because we're going to increment before using it
    indent = -1

    lines = {}
    stack = data.stack
    return data.fullError unless stack and next stack

    for i = 1, #stack do
        indent = indent + 1
        item = stack[i]

        lineNumber = item.currentline
        src = item.short_src or item.source or "<unknown source>"

        name = item.name or ""
        name = "<unknown>" if #name == 0

        spacing = string.rep " ", indent
        table.insert lines, "#{spacing}#{i}.  #{name} - #{src}:#{lineNumber}"

    table.concat lines, "\n"
