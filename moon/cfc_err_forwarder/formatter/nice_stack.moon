(data) ->
    indent = 2

    lines = {data.fullError or "<unknown error>"}
    stack = data.stack

    for i = 1, #stack do
        indent = indent + 1
        item = stack[i]

        lineNumber = item.currentline
        src = item.short_src or item.source or "<unknown source>"

        name = item.name
        name = "unknown" if #name == 0

        spacing = string.rep " ", indent
        table.insert lines, "#{spacing}#{i}.  #{name} - #{src}:#{lineNumber}"

    table.concat lines, "\n"
