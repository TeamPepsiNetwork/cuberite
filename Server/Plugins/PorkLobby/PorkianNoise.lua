-- simplified perlin noise
-- by DaPorkchop_
-- didn't feel like trying to port something so i wrote it myself. jeez. why do i do this?!?!?!?

NOISE_CACHE = {}

function InitNoise()
    local path = LOCAL_FOLDER .. "/noise.json"
    if (cFile:IsFile(path)) then
        NOISE_CACHE = cJson:Parse(cFile:ReadWholeFile(path))
        assert(#NOISE_CACHE == 256, "Noise cache must contain exactly 256 values, but we found " .. #NOISE_CACHE .. "!")
    else
        LOG("Generating random noise...")
        for i = 1, 512 do -- warm up RNG
            math.random()
        end
        NOISE_CACHE = {}
        for i = 1, 256 do
            NOISE_CACHE[i] = math.random(-256, 256)
        end
        local file = io.open(path, "w+")
        file:write(cJson:Serialize(NOISE_CACHE))
        file:close()
        LOG("Noise generated!")
    end
end

function GetOctaveNoise3d(x, y, z, octaves)
    local val = 0.0
    local mult = 1.0
    local fact = 1.0
    for o in 1, octaves do
        val = val + GetBaseNoise3d(x * mult, y * mult, z * mult) * fact
        mult = mult * 2.0
        fact = fact / 2.0
    end
    return val
end

function GetOctaveNoise2d(x, y, octaves)
    local val = 0.0
    local mult = 1.0
    local fact = 1.0
    for o in 1, octaves do
        val = val + GetBaseNoise2d(x * mult, y * mult) * fact
        mult = mult * 2.0
        fact = fact / 2.0
    end
    return val
end

function GetOctaveNoise1d(x, octaves)
    local val = 0.0
    local mult = 1.0
    local fact = 1.0
    for o in 1, octaves do
        val = val + GetBaseNoise1d(x * mult) * fact
        mult = mult * 2.0
        fact = fact / 2.0
    end
    return val
end

function GetBaseNoise3d(x, y, z)
    local fX = math.floor(x)
    local fY = math.floor(y)
    local fZ = math.floor(z)
    x = Fade(x - fX)
    y = Fade(y - fY)
    z = Fade(z - fZ)

    local x1 = Lerp(Hash3d(fX, fY, fZ), Hash3d(fX + 1, fY, fZ), x)
    local x2 = Lerp(Hash3d(fX, fY + 1, fZ), Hash3d(fX + 1, fY + 1, fZ), x)
    local y1 = Lerp(x1, x2, y)
    x1 = Lerp(Hash3d(fX, fY, fZ + 1), Hash3d(fX + 1, fY, fZ + 1), x)
    x2 = Lerp(Hash3d(fX, fY + 1, fZ + 1), Hash3d(fX + 1, fY + 1, fZ + 1), x)
    local y2 = Lerp(x1, x2, y)

    return Lerp(y1, y2, z)
end

function GetBaseNoise2d(x, y)
    local fX = math.floor(x)
    local fY = math.floor(y)
    x = Fade(x - fX)
    y = Fade(y - fY)

    local x1 = Lerp(Hash2d(fX, fY), Hash2d(fX + 1, fY), x)
    local x2 = Lerp(Hash2d(fX, fY + 1), Hash2d(fX + 1, fY + 1), x)

    return Lerp(x1, x2, y)
end

function GetBaseNoise1d(x)
    local fX = math.floor(x)
    x = Fade(x - fX)

    return Lerp(Hash1d(fX), Hash1d(fX + 1), x)
end

function Hash3d(x, y, z)
    return bit.bxor(bit.bxor(NOISE_CACHE[x * 2047 % 256 + 1], NOISE_CACHE[y * 8191 % 256 + 1]), NOISE_CACHE[z * 131071 % 256 + 1])
end

function Hash2d(x, y)
    return bit.bxor(NOISE_CACHE[x * 2047 % 256 + 1], NOISE_CACHE[y * 8191 % 256 + 1])
end

function Hash1d(x)
    return NOISE_CACHE[x * 2047 % 256 + 1]
end

function Fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end


function Lerp(v1, v2, t)
    return v1 + t * (v2 - v1)
end
