local prettyFunc = include( "formatter/pretty_function.lua" )
local formatRawValue

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

formatRawValue = function( val )
    local typeID = TypeID( val )

    if typeID == TYPE_NIL then
        return { _type = "nil" }
    elseif typeID == TYPE_BOOL then
        return val
    elseif typeID == TYPE_NUMBER then
        return val
    elseif typeID == TYPE_STRING then
        return val
    elseif IsColor( val ) then
        return {
            _type = "Color",
            data = {
                r = val.r,
                g = val.g,
                b = val.b,
                a = val.a,
            }
        }
    elseif typeID == TYPE_TABLE then
        local formatted = {}

        for k, v in pairs( val ) do
            formatted[k] = formatRawValue( v )
        end

        return formatted
    elseif typeID == TYPE_FUNCTION then
        return {
            _type = "Function",
            name = prettyFunc( val ),
        }
    elseif typeID == TYPE_ENTITY then
        if not IsValid( val ) then
            return {
                _type = "Entity [NULL]",
                data = {}
            }
        end

        return {
            _type = "Entity",
            data = {
                class = val:GetClass(),
                name = val:GetName(),
                model = val:GetModel(),
                pos = formatRawValue( val:GetPos() ),
                ang = formatRawValue( val:GetAngles() ),
            }
        }
    elseif typeID == TYPE_VECTOR then
        return {
            _type = "Vector",
            data = {
                x = val.x,
                y = val.y,
                z = val.z,
            }
        }
    elseif typeID == TYPE_ANGLE then
        return {
            _type = "Angle",
            data = {
                p = val.p,
                y = val.y,
                r = val.r,
            }
        }
    elseif typeID == TYPE_PHYSOBJ then
        local mins, maxs = val:GetAABB()

        return {
            _type = "PhysObj",
            data = {
                aabb = {
                    min = formatRawValue( mins ),
                    max = formatRawValue( maxs ),
                },
                angleVelocity = formatRawValue( val:GetAngleVelocity() ),
                energy = val:GetEnergy(),
                entity = formatRawValue( val:GetEntity() ),
                material = formatRawValue( val:GetMaterial() ),
                mass = val:GetMass(),
                name = val:GetName(),
                pos = val:GetPos(),
                volume = formatRawValue( val:GetVolume() ),
                vel = formatRawValue( val:GetVelocity() ),
                status = {
                    isAsleep = val:IsAsleep(),
                    isCollisionEnabled = val:IsCollisionEnabled(),
                    isDragEnabled = val:IsDragEnabled(),
                    isGravityEnabled = val:IsGravityEnabled(),
                    isMotionEnabled = val:IsMotionEnabled(),
                    isMoveable = val:IsMoveable(),
                    isPenetrating = val:IsPenetrating(),
                    isValid = val:IsValid(),
                }
            }
        }
    elseif typeID == TYPE_DAMAGEINFO then
        return {
            _type = "CTakeDamageInfo",
            data = {
                ammo = game.GetAmmoName( val:GetAmmoType() ),
                attacker = formatRawValue( val:GetAttacker() ),
                damage = val:GetDamage(),
                damageBonus = val:GetDamageBonus(),
                damageForce = formatRawValue( val:GetDamageForce() ),
                damageType = val:GetDamageType(),
                damageTypes = getDamageTypes( val ),
                inflictor = formatRawValue( val:GetInflictor() ),
            }
        }
    elseif typeID == TYPE_EFFECTDATA then
        return {
            _type = "CEffectData",
            data = {
                angles = formatRawValue( val:GetAngles() ),
                attachmentIndex = val:GetAttachment(),
                color = val:GetColor(),
                entity = formatRawValue( val:GetEntity() ),
                magnitude = val:GetMagnitude(),
                normal = formatRawValue( val:GetNormal() ),
                origin = formatRawValue( val:GetOrigin() ),
                radius = val:GetRadius(),
                scale = val:GetScale(),
            }
        }
    elseif typeID == TYPE_MOVEDATA then
        return {
            _type = "CMoveData",
            data = {
                angles = formatRawValue( val:GetAngles() ),
                buttons = getButtons( val ),
                forwardSpeed = val:GetForwardSpeed(),
                impulse = val:GetImpulse(),
                maxSpeed = val:GetMaxSpeed(),
                moveAngles = formatRawValue( val:GetMoveAngles() ),
                origin = formatRawValue( val:GetOrigin() ),
            }
        }
    elseif typeID == TYPE_RECIPIENTFILTER then
        return {
            _type = "CRecipientFilter",
            data = {
                count = val:GetCount(),
                players = formatTable( val:GetPlayers() ),
            }
        }
    elseif typeID == TYPE_USERCMD then
        return {
            _type = "CUserCmd",
            data = {
                commandNumber = val:GetCommandNumber(),
                buttons = getButtons( val ),
                forwardMove = formatRawValue( val:GetForwardMove() ),
                impulse = val:GetImpulse(),
                mouseX = val:GetMouseX(),
                mouseY = val:GetMouseY(),
                sideMove = val:GetSideMove(),
                upMove = val:GetUpMove(),
                viewAngles = formatRawValue( val:GetViewAngles() ),
                isForced = val:IsForced(),
            }
        }
    elseif typeID == TYPE_MATERIAL then
        return {
            _type = "IMaterial",
            data = {
                name = val:GetName(),
                shader = val:GetShader(),
                string = val:GetString(),
                texture = val:GetTexture(),
            }
        }
    elseif typeID == TYPE_PARTICLE then
        return {
            _type = "CLuaParticle",
            data = {
                color = formatRawValue( val:GetColor() ),
                dieTime = val:GetDieTime(),
                pos = formatRawValue( val:GetPos() ),
                rotation = val:GetRoll(),
                velocity = formatRawValue( val:GetVelocity() ),
            }
        }
    elseif typeID == TYPE_TEXTURE then
        return {
            _type = "ITexture",
            data = {
                name = val:GetName(),
                height = val:GetTall(),
                width = val:GetWide(),
            }
        }
    elseif typeID == TYPE_MESH then
        return {
            _type = "IMesh",
            data = {
                isValid = val:IsValid(),
            }
        }
    elseif typeID == TYPE_MATRIX then
        return {
            _type = "VMatrix",
            data = formatTable( val:ToTable() )
        }
    elseif typeID == TYPE_SOUND then
        return {
            _type = "CSoundPatch",
            data = {
                _isPlaying = val:IsPlaying(),
                dsp = val:GetDSP(),
                pitch = val:GetPitch(),
                soundLevel = val:GetSoundLevel(),
                volume = val:GetVolume(),
            }
        }
    elseif typeID == TYPE_FILE then
        return {
            _type = "File",
            data = {
                size = val:Size(),
                tell = val:Tell(),
                endOfFile = val:EndOfFile(),
            }
        }
    elseif typeID == TYPE_LOCOMOTION then
        return {
            _type = "CLuaLocomotion",
            data = {
                acceleration = val:GetAcceleration(),
                avoidAllowed = val:GetAvoidAllowed(),
                climbAllowed = val:GetClimbAllowed(),
                desiredSpeed = val:GetDesiredSpeed(),
                groundMotionVector = formatRawValue( val:GetGroundMotionVector() ),
                groundNormal = formatRawValue( val:GetGroundNormal() ),
                nextBot = val:GetNextBot(),
                velocity = formatRawValue( val:GetVelocity() ),
                attemptingToMove = val:IsAttemptingToMove(),
                climbingOrJumping = val:IsClimbingOrJumping(),
                isOnGround = val:IsOnGround(),
                isStuck = val:IsStuck(),
                isUsingLadder = val:IsUsingLadder(),
            }
        }
    elseif typeID == TYPE_PATH then
        return {
            _type = "PathFollower",
            data = {
                age = formatRawValue( val:GetAge() ),
                goal = val:GetCurrentGoal(),
                endPos = formatRawValue( val:GetEnd() ),
                length = val:GetLength(),
                startPos = formatRawValue( val:GetStart() ),
                isValid = val:IsValid(),
            }
        }
    elseif typeID == TYPE_PHYSCOLLIDE then
        return {
            _type = "PhysCollide",
            data = {
                isValid = val:IsValid(),
            }
        }
    elseif typeID == TYPE_SURFACEINFO then
        return {
            _type = "SurfaceInfo",
            data = {
                material = formatRawValue( val:GetMaterial() ),
                isNoDraw = val:IsNoDraw(),
                isSky = val:IsSky(),
                isWater = val:IsWater(),
            }
        }
    else
        return {
            _typeID = typeID,
            data = tostring( val )
        }
    end
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
            print( "upvalue", name, value )
            upvalues[name] = formatRawValue( value )
        end
    end

    return upvalues
end

local function getLocals( item )
    local locals = {}
    local rawLocals = item.locals
    if not rawaLocals then return {} end

    for name, value in pairs( rawLocals ) do
        print( "locals", name, value )
        locals[name] = formatRawValue( value )
    end

    return locals
end

return function( stack )
    local stackLocals = {}
    local stackUpvalues = {}

    local stackCount = #stack

    for i = 1, stackCount do
        local level = stack[i]
        local funcName = prettyFunc( level.func )
        local fileAndLine = string.format( "%s:%s", level.short_src, level.currentline )

        stackLocals[i] = {
            stackLevel = i,
            funcName = funcName,
            fileAndLine = fileAndLine,
            locals = getLocals( level )
        }

        stackUpvalues[i] = {
            stackLevel = i,
            funcName = funcName,
            fileAndLine = fileAndLine,
            upvalues = getUpvalues( level )
        }
    end

    return stackLocals, stackUpvalues
end
