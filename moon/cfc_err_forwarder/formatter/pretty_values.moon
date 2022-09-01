import Round from math
round = (n) -> Round n, 3

prettyFunc = include "cfc_err_forwarder/formatter/pretty_function.lua"

(val) ->
    switch TypeID val
        when TYPE_NIL
            "Nil []"

        when TYPE_BOOL
            "Bool [#{val}]"

        when TYPE_NUMBER
            "Number [#{round val}]"

        when TYPE_STRING
            "String [\"" .. val .. "\"]"

        when TYPE_TABLE
            "Table [#{val}]"

        when TYPE_FUNCTION
            "Function [#{prettyFunc val}]"

        when TYPE_VECTOR
            "Vector [#{round val[1]}, #{round val[2]}, #{round val[3]}]"

        when TYPE_ANGLE
            "Angle [#{round val[1]}, #{round val[2]}, #{round val[3]}]"

        when TYPE_DAMAGEINFO
            "DamageInfo [#{round val\GetDamage!} dmg]"

        -- TODO?: Make some wacky file.Open wrapper that returns
        -- a file_obj-like table with a GetPath method on it
        -- when TYPE_FILE
        --     "File[#{val\GetPath!}]"

        when TYPE_EFFECTDATA
            "EffectData [#{val\GetEntity!}]"

        when TYPE_SURFACEINFO
            mat = val\GetMaterial!
            "SurfaceInfo [#{mat and mat\GetName! or [[""]]}]"

        else
            tostring val

