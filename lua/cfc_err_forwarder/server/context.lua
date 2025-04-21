local prettyFunc = include( "formatter/pretty_function.lua" ).FromFunction

local tostring = tostring
local fmt = string.format

local _formatRawValue

local keys = {
    [IN_ATTACK] = "Attack",
    [IN_JUMP] = "Jump",
    [IN_DUCK] = "Duck",
    [IN_FORWARD] = "Forward",
    [IN_BACK] = "Back",
    [IN_USE] = "Use",
    [IN_CANCEL] = "Cancel",
    [IN_LEFT] = "Left",
    [IN_RIGHT] = "Right",
    [IN_MOVELEFT] = "Move Left",
    [IN_MOVERIGHT] = "Move Right",
    [IN_ATTACK2] = "Attack 2",
    [IN_RUN] = "Run",
    [IN_RELOAD] = "Reload",
    [IN_ALT1] = "Alt 1",
    [IN_ALT2] = "Alt 2",
    [IN_SCORE] = "Score",
    [IN_SPEED] = "Speed",
    [IN_WALK] = "Walk",
    [IN_ZOOM] = "Zoom",
    [IN_WEAPON1] = "Weapon 1",
    [IN_WEAPON2] = "Weapon 2",
    [IN_BULLRUSH] = "Bull Rush",
    [IN_GRENADE1] = "Grenade 1",
    [IN_GRENADE2] = "Grenade 2",
}

local function getButtons( moveData )
    local buttons = {}

    for k, v in pairs( keys ) do
        if moveData:KeyDown( k ) then
            table.insert( buttons, v )
        end
    end

    table.sort( buttons )

    return buttons
end

local damageTypes = {
    [DMG_GENERIC] = "Generic",
    [DMG_CRUSH] = "Crush",
    [DMG_BULLET] = "Bullet",
    [DMG_SLASH] = "Slash",
    [DMG_BURN] = "Burn",
    [DMG_VEHICLE] = "Vehicle",
    [DMG_FALL] = "Fall",
    [DMG_BLAST] = "Blast",
    [DMG_CLUB] = "Club",
    [DMG_SHOCK] = "Shock",
    [DMG_SONIC] = "Sonic",
    [DMG_ENERGYBEAM] = "Energy Beam",
    [DMG_PREVENT_PHYSICS_FORCE] = "Prevent Physics Force",
    [DMG_NEVERGIB] = "Never Gib",
    [DMG_ALWAYSGIB] = "Always Gib",
    [DMG_DROWN] = "Drown",
    [DMG_PARALYZE] = "Paralyze",
    [DMG_NERVEGAS] = "Nerve Gas",
    [DMG_POISON] = "Poison",
    [DMG_RADIATION] = "Radiation",
    [DMG_DROWNRECOVER] = "Drown Recover",
    [DMG_ACID] = "Acid",
    [DMG_SLOWBURN] = "Slow Burn",
    [DMG_REMOVENORAGDOLL] = "Remove No Ragdoll",
    [DMG_PHYSGUN] = "Physgun",
    [DMG_PLASMA] = "Plasma",
    [DMG_AIRBOAT] = "Airboat",
    [DMG_DISSOLVE] = "Dissolve",
    [DMG_BLAST_SURFACE] = "Blast Surface",
    [DMG_DIRECT] = "Direct",
    [DMG_BUCKSHOT] = "Buckshot",
    [DMG_SNIPER] = "Sniper",
    [DMG_MISSILEDEFENSE] = "Missile Defense",
}

local function getDamageTypes( damageInfo )
    local types = {}

    for k, v in pairs( damageTypes ) do
        if damageInfo:IsDamageType( k ) then
            table.insert( types, v )
        end
    end

    table.sort( types )

    return types
end

--- @class FormattedRawValueShort
--- @field name string? The human friendly name of the value. Omit to use the normal name, set to "" to not display a name
--- @field val string The human friendly short value
--- @field newline string? Should break the definition from the name in the short output

--- @class RawValueDetails
--- @field name string The human-friendly type of the value
--- @field data table? Extra fields to give more context for the value. May not be present for simple values
--- @field val any The actual value itself
--- @field short FormattedRawValueShort The data to build a short one-liner for limited context

--- Internal funtion to generate the first set of value details
--- @return RawValueDetails
_formatRawValue = function( val, _seen )
    local typeID = TypeID( val )

    if typeID == TYPE_NIL then
        return {
            name = "Nil",
            short = { val = "" }
        }

    elseif typeID == TYPE_BOOL then
        return {
            name = "Boolean",
            short = { name = "" }
        }

    elseif typeID == TYPE_NUMBER then
        return {
            name = "Number",
            short = {
                name = "",
                val = val,
                newline = true
            }
        }

    elseif typeID == TYPE_STRING then
        local shortVal = val
        if #val > 48 then
            shortVal = string.sub( val, 1, 48 ) .. "..."
        end

        return {
            name = "String",
            short = {
                name = "",
                val = fmt( [["%s"]], shortVal ),
                newline = true
            }
        }

    elseif IsColor( val ) then
        local r = val.r
        local g = val.g
        local b = val.b
        local a = val.a

        return {
            name = "Color",
            data = { r = r, g = g, b = b, a = a },
            short = { val = fmt( "%d, %d, %d, %d", r, g, b, a ) }
        }

    elseif typeID == TYPE_TABLE then
        local formatted = {}
        _seen = _seen or {}

        for k, v in pairs( val ) do
            if not _seen[v] then
                _seen[v] = true

                local parsed = _formatRawValue( v, _seen )
                parsed.val = parsed.val or tostring( v )
                formatted[k] = parsed
            end
        end

        local shortName
        local shortVal

        local formattedCount = table.Count( formatted )
        if formattedCount == 0 then
            shortName = ""
            shortVal = "{}"
        else
            shortVal = fmt( "#%d", formattedCount )
        end

        return {
            name = "Table",
            data = formatted,
            short = { name = shortName, val = shortVal }
        }

    elseif typeID == TYPE_FUNCTION then
        local pretty = prettyFunc( val )

        return {
            name = "Function",
            val = pretty,
            data = { source = pretty },
            short = {
                name = "Func",
                val = fmt( [["%s"]], pretty ),
                newline = true
            }
        }

    elseif typeID == TYPE_ENTITY then
        local isValid = IsValid( val )

        -- Can't add any extra info about a NULL Entity
        if not isValid then
            return {
                name = "Entity",
                data = { isValid = isValid },
                short = { val = "NULL" }
            }
        end

        local class = val:GetClass()

        if class == "player" then
            return {
                name = "Player",
                data = {
                    steamID = val:SteamID(),
                    steamID64 = val:SteamID64(),
                    nickname = val:Nick(),
                    ping = val:Ping(),
                    packetLoss = val:PacketLoss(),
                    health = val:Health(),
                    armor = val:Armor(),
                    alive = val:Alive(),
                    model = val:GetModel(),
                    flashlight = val:FlashlightIsOn(),
                    weapon = val:GetActiveWeapon(),
                    aimEnt = val:GetEyeTrace().Entity,
                    vehicle = val:GetVehicle(),
                    god = val:HasGodMode(),
                    timeConnected = val:TimeConnected(),
                    connected = val:IsConnected(),
                    frozen = val:IsFrozen(),
                    timingOut = val:IsTimingOut(),
                    sprinting = val:IsSprinting(),
                    typing = val:IsTyping()
                },
                short = {
                    val = fmt( [["%s"]], val:SteamID() )
                }
            }
        end

        return {
            name = "Entity",
            data = {
                class = class,
                name = val:GetName(),
                model = val:GetModel(),
                pos = val:GetPos(),
                ang = val:GetAngles(),
                isValid = isValid
            },
            short = { val = fmt( [["%s"]], class ) }
        }

    elseif typeID == TYPE_VECTOR then
        local x = val.x
        local y = val.y
        local z = val.z

        return {
            name = "Vector",
            data = { x = x, y = y, z = z },
            short = {
                val = fmt( "%d, %d, %d", x, y, z ),
            }
        }

    elseif typeID == TYPE_ANGLE then
        local p = val.p
        local y = val.y
        local r = val.r

        return {
            name = "Angle",
            data = { p = p, y = y, r = r },
            short = {
                val = fmt( "%d, %d, %d", p, y, r )
            }
        }

    elseif typeID == TYPE_PHYSOBJ then
        local isValid = val:IsValid()

        if not isValid then
            return {
                name = "PhysObj",
                data = { isValid = false },
                short = { val = "NULL" }
            }
        end

        local mins, maxs = val:GetAABB()
        local ent = val:GetEntity()

        return {
            name = "PhysObj",
            data = {
                aabb = {
                    min = mins,
                    max = maxs,
                },
                angleVelocity = val:GetAngleVelocity(),
                energy = val:GetEnergy(),
                entity = ent,
                material = val:GetMaterial(),
                mass = val:GetMass(),
                name = val:GetName(),
                pos = val:GetPos(),
                volume = val:GetVolume(),
                vel = val:GetVelocity(),
                status = {
                    isAsleep = val:IsAsleep(),
                    isCollisionEnabled = val:IsCollisionEnabled(),
                    isDragEnabled = val:IsDragEnabled(),
                    isGravityEnabled = val:IsGravityEnabled(),
                    isMotionEnabled = val:IsMotionEnabled(),
                    isMoveable = val:IsMoveable(),
                    isPenetrating = val:IsPenetrating(),
                },
                isValid = val:IsValid(),
            },
            short = {
                val = tostring( ent ),
                newline = true
            }
        }

    elseif typeID == TYPE_DAMAGEINFO then
        local damage = val:GetDamage()
        local attacker = val:GetAttacker()

        return {
            name = "CTakeDamageInfo",
            data = {
                ammo = game.GetAmmoName( val:GetAmmoType() ),
                attacker = attacker,
                damage = damage,
                damageBonus = val:GetDamageBonus(),
                damageForce = val:GetDamageForce(),
                damageType = val:GetDamageType(),
                damageTypes = getDamageTypes( val ),
                inflictor = val:GetInflictor(),
            },
            short = {
                name = "Dmg",
                val = fmt( "%s->%d", tostring( attacker ), damage ),
                newline = true
            }
        }

    elseif typeID == TYPE_EFFECTDATA then
        local ent = val:GetEntity()

        return {
            name = "CEffectData",
            data = {
                angles = val:GetAngles(),
                attachmentIndex = val:GetAttachment(),
                color = val:GetColor(),
                entity = ent,
                magnitude = val:GetMagnitude(),
                normal = val:GetNormal(),
                origin = val:GetOrigin(),
                radius = val:GetRadius(),
                scale = val:GetScale(),
            },
            short = {
                name = "Effect",
                val = tostring( ent )
            }
        }

    elseif typeID == TYPE_MOVEDATA then
        return {
            name = "CMoveData",
            data = {
                angles = val:GetAngles(),
                buttons = getButtons( val ),
                forwardSpeed = val:GetForwardSpeed(),
                impulse = val:GetImpulse(),
                maxSpeed = val:GetMaxSpeed(),
                moveAngles = val:GetMoveAngles(),
                origin = val:GetOrigin(),
            },
            short = { val = "" }
        }

    elseif typeID == TYPE_RECIPIENTFILTER then
        local count = val:GetCount()

        return {
            name = "CRecipientFilter",
            data = {
                count = count,
                players = val:GetPlayers(),
            },
            short = { val = fmt( "#%d", count ) }
        }

    elseif typeID == TYPE_USERCMD then
        return {
            name = "CUserCmd",
            data = {
                commandNumber = val:GetCommandNumber(),
                buttons = getButtons( val ),
                forwardMove = val:GetForwardMove(),
                impulse = val:GetImpulse(),
                mouseX = val:GetMouseX(),
                mouseY = val:GetMouseY(),
                sideMove = val:GetSideMove(),
                upMove = val:GetUpMove(),
                viewAngles = val:GetViewAngles(),
                isForced = val:IsForced(),
            },
            short = { val = "" }
        }

    elseif typeID == TYPE_MATERIAL then
        local name = val:GetName()

        return {
            name = "IMaterial",
            data = {
                name = name,
                shader = val:GetShader(),
                texture = val:GetTexture( "$basetexture" ),
            },
            short = { name = "Mat", val = fmt( [["%s"]], name ) }
        }

    elseif typeID == TYPE_PARTICLE then
        return {
            name = "CLuaParticle",
            data = {
                color = val:GetColor(),
                dieTime = val:GetDieTime(),
                pos = val:GetPos(),
                rotation = val:GetRoll(),
                velocity = val:GetVelocity(),
            },
            short = { name = "Particle", val = "" }
        }

    elseif typeID == TYPE_TEXTURE then
        local name = val:GetName()

        return {
            name = "ITexture",
            data = {
                name = name,
                height = val:Height(),
                width = val:Width(),
            },
            short = {
                name = "Texture",
                val = val
            }
        }

    elseif typeID == TYPE_MESH then
        return {
            name = "IMesh",
            data = {
                isValid = val:IsValid(),
            },
            short = { name = "Mesh", val = "" }
        }

    elseif typeID == TYPE_MATRIX then
        return {
            name = "VMatrix",
            data = val:ToTable(),
            short = { name = "Matrix", val = "" }
        }

    elseif typeID == TYPE_SOUND then
        local isPlaying = val:IsPlaying()

        return {
            name = "CSoundPatch",
            data = {
                isPlaying = isPlaying,
                dsp = val:GetDSP(),
                pitch = val:GetPitch(),
                soundLevel = val:GetSoundLevel(),
                volume = val:GetVolume(),
            },
            short = {
                name = "Sound",
                val = isPlaying and "on" or "off"
            }
        }

    elseif typeID == TYPE_FILE then
        local size = val:Size()
        local tell = val:Tell()

        return {
            name = "File",
            data = {
                size = size,
                tell = tell,
                endOfFile = val:EndOfFile(),
            },
            short = {
                val = fmt( "%d/%d", tell, size )
            }
        }

    elseif typeID == TYPE_LOCOMOTION then
        return {
            name = "CLuaLocomotion",
            data = {
                acceleration = val:GetAcceleration(),
                avoidAllowed = val:GetAvoidAllowed(),
                climbAllowed = val:GetClimbAllowed(),
                desiredSpeed = val:GetDesiredSpeed(),
                groundMotionVector = val:GetGroundMotionVector(),
                groundNormal = val:GetGroundNormal(),
                nextBot = val:GetNextBot(),
                velocity = val:GetVelocity(),
                attemptingToMove = val:IsAttemptingToMove(),
                climbingOrJumping = val:IsClimbingOrJumping(),
                isOnGround = val:IsOnGround(),
                isStuck = val:IsStuck(),
                isUsingLadder = val:IsUsingLadder(),
            },
            short = { val = "" }
        }

    elseif typeID == TYPE_PATH then
        local isValid = val:IsValid()

        if not isValid then
            return {
                name = "PathFollower",
                data = { isValid = isValid },
                short = { val = "NULL" }
            }
        end

        return {
            name = "PathFollower",
            data = {
                age = val:GetAge(),
                goal = val:GetCurrentGoal(),
                endPos = val:GetEnd(),
                length = val:GetLength(),
                startPos = val:GetStart(),
                isValid = isValid,
            },
            short = { val = "" }
        }

    elseif typeID == TYPE_PHYSCOLLIDE then
        return {
            name = "PhysCollide",
            data = { isValid = val:IsValid(), },
            short = { val = isValid and "" or "NULL" }
        }

    elseif typeID == TYPE_SURFACEINFO then
        local mat = val:GetMaterial()
        return {
            name = "SurfaceInfo",
            data = {
                material = mat,
                isNoDraw = val:IsNoDraw(),
                isSky = val:IsSky(),
                isWater = val:IsWater(),
            },
            short = {
                name = "Surface",
                val = mat:GetName()
            }
        }

    else
        return {
            name = "Unknown",
            short = { val = type( val ) }
        }
    end
end

local canRaw = {
    Number = true,
    Boolean = true,
    String = true
}

local function formatRawValue( val )
    local out = _formatRawValue( val )

    if not out.val then
        out.val = canRaw[out.name] and val or tostring( val )
    end

    local short = out.short
    if short then
        short.val = short.val ~= nil and tostring( short.val ) or out.val
    end

    -- if out.name ~= "Table" then
    --     local data = out.data

    --     if data then
    --         for key, value in pairs( data ) do
    --             local parsed = _formatRawValue( value )
    --             parsed.val = parsed.val or tostring( value )

    --             short = parsed.short
    --             if short then
    --                 short.val = short.val ~= nil and tostring( short.val ) or parsed.val
    --             end

    --             data[key] = parsed
    --         end
    --     end
    -- end

    return out
end

local function getUpvalues( item )
    local what = item.what
    if what ~= "Lua" then return end

    local func = item.func
    local nups = item.nups

    local upvalues = {}
    for i = 1, nups do
        local name, value = debug.getupvalue( func, i )
        if value ~= nil then
            upvalues[name] = formatRawValue( value )
        end
    end

    return upvalues
end

local function getLocals( item )
    local locals = {}
    local rawLocals = item.locals
    if not rawLocals then return {} end

    for name, value in pairs( rawLocals ) do
        local v = formatRawValue( value )
        locals[name] = v
    end

    return locals
end

return function( stack )
    local stackLocals = {}
    local stackUpvalues = {}

    local stackCount = #stack

    for i = 1, stackCount do
        local level = stack[i]

        local locals = getLocals( level )
        stackLocals[i] = {
            locals = locals
        }

        if ( locals and next( locals ) ) then break end
    end

    for i = 1, stackCount do
        local level = stack[i]

        local upvalues = getUpvalues( level )
        stackUpvalues[i] = {
            upvalues = upvalues
        }

        if ( upvalues and next( upvalues ) ) then break end
    end

    return stackLocals, stackUpvalues
end
