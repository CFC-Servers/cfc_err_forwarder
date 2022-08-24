bold = (text) -> "**#{text}**"
code = (text, language="") -> "```#{language}\n#{text}```"

timestamp = -> os.date "%Y-%m-%d %H:%M", os.time!
humanTimestamp = (ts) -> os.date "%X %x", ts

bad = (text) ->
    text = "- #{text}"
    code text, "diff"

truncate = (text, max=1024) ->
    return text if #text < max
    return "#{string.Left text, max - 10}..."

:bad, :bold, :code, :truncate, :timestamp, :humanTimestamp
