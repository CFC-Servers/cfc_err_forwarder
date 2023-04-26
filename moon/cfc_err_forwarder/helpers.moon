pretty = include "cfc_err_forwarder/formatter/pretty_values.lua"

stripStack = (tbl) ->
    for _, stackObj in pairs tbl
        stackObj.upvalues = nil
        stackObj.activelines = nil

stringTable = (tbl) ->
    oneline = table.Count(tbl) == 1

    str = "{"
    str ..= "\n" unless oneline

    count = 0
    for k, v in pairs tbl
        break if count >= 5

        str ..= "  #{k} = #{pretty v}"
        str ..= oneline and " " or "\n"

        count += 1

    str ..= "}"

    str


saveLocals = (stack) ->
    for _, stackObj in pairs stack
        locals = stackObj.locals
        continue unless locals

        newLocals = {}
        for name, value in pairs locals
            if istable value
                newLocals[name] = stringTable value
            else
                newLocals[name] = pretty value

                newLocal = newLocals[name]
                if #newLocal > 125
                    newLocals[name] = "#{string.Left newLocal, 122}..."

        stackObj.locals = newLocals

return { :stripStack, :saveLocals }
