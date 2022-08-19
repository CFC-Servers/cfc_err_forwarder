red = 14483456
bold = (text) -> "**#{text}**"

code = (text, language="") -> "```#{language}\n#{text}```"

timestamp = -> os.date "%Y-%m-%d %H:%M", os.time!
humanTimesamp = (ts) -> os.date "%X %x", ts

bad = (text) ->
    text = "- #{text}"
    code text, "diff"

truncate = (text, max=1024) ->
    return text if #text < max
    return "#{string.Left(text, max - 10)}..."

niceStack = (stackData) ->
    indent = 2

    lines = { stackData.fullError or "<unknown error>" }
    stack = stackData.stack

    for i = 1, #stack do
        indent += 1

        item = stack[i]

        lineNumber = item.currentLine
        src = item.short_src or item.source or "<unknown source>"

        name = item.name
        name = "unknown" if #name == 0

        spacing = string.rep " ", indent
        table.insert lines, "#{spacing}#{i}.  #{name} - #{src}:#{lineNumber}"

    table.concat lines, "\n"

return (data) ->
    realm = data.isClientside and "Client" or "Server"

    {
        content: "",
        embeds: {
            {
                title: "#{realm} Error"
                description: bad data.errorString
                color: red
                fields: {
                    {
                        name: "Source File"
                        value: code "#{data.sourceFile}:#{data.sourceLine}"
                    },

                    {
                        name: "Full Error"
                        value: code truncate niceStack data.fullError
                    },

                    {
                        name: "Count per #{data.reportInterval} seconds"
                        value: bold data.count
                    },

                    {
                        name: "Most recent occurrence"
                        value: code humanTimesamp data.occurredAt
                    }
                },
                author: timestamp: timestamp
            }
        }
    }
