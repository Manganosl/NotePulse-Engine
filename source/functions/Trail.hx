package functions;

class Trail{
    public static var script:String = "
    local bfColor = '31B0D1'
local dadColor = '31B0D1'
local gfColor = '31B0D1'
local lastDadHoldTime = 0
local lastDadStrum = 0
local lastBfHoldTime = 0
local lastBfStrum = 0
local lastGfHoldTime = 0
local lastGfStrum = 0
local bfAnim = {}
local dadAnim = {}
local gfAnim = {}
local enableDadGhost = true
local enableBfGhost = true
local enableGfGhost = true
function onCreatePost()
    detectGhostColor()
end
function detectGhostColor()
    bfColor = rgb({getProperty('boyfriend.healthColorArray[0]'),getProperty('boyfriend.healthColorArray[1]'),getProperty('boyfriend.healthColorArray[2]')})
    dadColor = rgb({getProperty('dad.healthColorArray[0]'),getProperty('dad.healthColorArray[1]'),getProperty('dad.healthColorArray[2]')})
    gfColor = rgb({getProperty('gf.healthColorArray[0]'),getProperty('gf.healthColorArray[1]'),getProperty('gf.healthColorArray[2]')})
end
function rgb(rgb)
    --Credits to marceloCodget for the script = https://gist.github.com/marceloCodget/3862929
	local hexadecimal = ''
	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end
		hexadecimal = hexadecimal .. hex
	end
    return hexadecimal
end
function onEvent(name,v1,v2)
    if name == 'Change Character' then
        detectGhostColor()
        if getProperty('dad.curCharacter') == 'charles' then
            enableDadGhost = false
        else
            enableDadGhost = true
        end
    end
end
function detectGF(type)
    if gfSection ~= true and type ~= 'GF Sing'  then
        return false
    else
        return true
    end
end
function opponentNoteHit(id,dir,type,sus)
    if not sus then
        local noteStrum = getPropertyFromGroup('notes',id,'strumTime')
        local noteSustain = getPropertyFromGroup('notes',id,'sustainLength')
        if noteSustain <= stepCrochet then
            noteSustain = 0
        end
        if not detectGF(type) then
            if enableDadGhost then
                if lastDadStrum ~= noteStrum then
                    saveAnim('dad')
                else
                    if noteSustain ~= nil and noteSustain > stepCrochet and lastDadHoldTime > noteSustain then
                        saveAnim('dad')
                    end
                    createGhost('dad',dadColor,{dadAnim[1][1],dadAnim[1][2],dadAnim[1][3]},getProperty('dad.imageFile'),getObjectOrder('dadGroup')-1,{dadAnim[1][4],dadAnim[1][5]})
                end
                lastDadStrum = noteStrum
                lastDadHoldTime = noteSustain
            end
        else
            if enableGfGhost then
                gfGhost(noteStrum,noteSustain)
            end
        end
    end
end
function gfGhost(noteStrum,noteSustain)
    if enableGfGhost then
        if lastGfStrum ~= noteStrum then
            saveAnim('gf')
        else
            if noteSustain > stepCrochet and lastGfHoldTime > noteSustain then
                saveAnim('gf')
            end
            createGhost('gf',gfColor,{gfAnim[1][1],gfAnim[1][2],gfAnim[1][3]},getProperty('gf.imageFile'),getObjectOrder('gfGroup')-1,{gfAnim[1][4],gfAnim[1][5]})
        end
        lastGfHoldTime = noteSustain
        lastGfStrum = noteStrum
    end
end
function saveAnim(character)
    local anim = getProperty(character..'.animation.frameName')
    anim = string.sub(anim,0,string.len(anim) - 3)
    local array = {}
    if character == 'bf' then
        character = 'boyfriend'
    end
    table.insert(array,anim)
    table.insert(array,getProperty(character..'.animation.curAnim.frameRate'))
    table.insert(array,getProperty(character..'.animation.curAnim.looped'))
    table.insert(array,getProperty(character..'.offset.x'))
    table.insert(array,getProperty(character..'.offset.y'))
    if character == 'boyfriend' then
        table.remove(bfAnim)
        table.insert(bfAnim,array)
    elseif character == 'dad' then
        table.remove(dadAnim)
        table.insert(dadAnim,array)
    elseif character == 'gf' then
        table.remove(gfAnim)
        table.insert(gfAnim,array)
    end
end
function goodNoteHit(id,dir,type,sus)
    if not sus then
        local noteStrum = getPropertyFromGroup('notes',id,'strumTime')
        local noteSustain = getPropertyFromGroup('notes',id,'sustainLength')
        if noteSustain <= stepCrochet then
            noteSustain = 0
        end
        if not detectGF(type) then
            if enableBfGhost then
                if lastBfStrum ~= noteStrum then
                    saveAnim('boyfriend')
                else
                    if --[[noteSustain > stepCrochet and]] lastBfHoldTime > noteSustain then
                        saveAnim('boyfriend')
                    end
                    createGhost('boyfriend',bfColor,{bfAnim[1][1],bfAnim[1][2],bfAnim[1][3]},getProperty('boyfriend'..'.imageFile'),getObjectOrder('boyfriendGroup')-1,{bfAnim[1][4],bfAnim[1][5]})
                end
                lastBfStrum = noteStrum
                lastBfHoldTime = noteSustain
            end
        else
            if enableGfGhost then
                gfGhost(noteStrum,noteSustain)
            end
        end
    end
end
--[[function detectGhost(character,color,strum,sus,lastStrum,lastHoldTime)
    local anim = nil
    if lastStrum == strum then
        if lastHoldTime > sus then
            setAnim(character,{
                    getProperty(character..'.animation.frameName'),
                    getProperty(character..'.animation.curAnim.frameRate'),
                    getProperty(character..'.animation.curAnim.looped'),
                    getProperty(character..'.offset.x'),
                    getProperty(character..'.offset.y')
                }
            )
        end
        if character == 'boyfriend' or character == 'bf' then
            table.insert(anim,{bfAnim[1],bfAnim[2],bfAnim[3]})
        elseif character == 'dad' then
            table.insert(anim,{dadAnim[1],dadAnim[2],dadAnim[3]})
        elseif character == 'gf' then
            table.insert(anim,{gfAnim[1],gfAnim[2],gfAnim[3]})
        end
        if anim ~= nil then
            createGhost(character,color,anim,getProperty(character..'.imageFile'),getObjectOrder(character..'Group')-1)
        end
    end
end]]--

function createGhost(character, color, anim, location, order, offset)
    if getProperty(character..'.alpha') > 0.3  and getProperty(character..'.visible') then
        local spriteName = character..'Ghost'
        cancelTween(spriteName..'Bye')
        makeAnimatedLuaSprite(spriteName, location, getProperty(character..'.x'), getProperty(character..'.y'))
        setProperty(spriteName..'.alpha', getProperty(character..'.alpha') - 0.3)
        scaleObject(spriteName, getProperty(character..'.scale.x'), getProperty(character..'.scale.y'))
        setProperty(spriteName..'.antialiasing',getProperty(character..'.antialiasing'))
        addAnimationByPrefix(spriteName,'anim',anim[1],anim[2],anim[3])
        setProperty(spriteName..'.color',getColorFromHex(color))
        setProperty(spriteName..'.flipX', getProperty(character..'.flipX'))
        setProperty(spriteName..'.angle', getProperty(character..'.angle'))
        objectPlayAnimation(spriteName,'anim',true)
        addLuaSprite(spriteName,false)
        doTweenAlpha(spriteName..'Bye',spriteName, 0, 0.5, 'linear')
        if order == nil then
            if character == 'boyfriend' or character == 'dad' or character == 'gf' then
                character = character..'Group'
            end
            order = getObjectOrder(character..'Group') - 1
        end
        setObjectOrder(spriteName,order)
        if offset ~= nil then
            setProperty(spriteName..'.offset.x',offset[1])
            setProperty(spriteName..'.offset.y',offset[2])
        end
    end
end

--[[function addGhostAnim(character, name, xml, frameRate, loop, offsetX, offsetY)
    local spriteAnim = character..'Ghost'
    if xml == nil then
        if character == 'dad' then
            xml = dadAnim[1][1]
        elseif character == 'boyfriend' then
            xml = bfAnim[1][1]
        elseif character == 'gf' then
            xml = gfAnim[1][1]
        else
            xml = getProperty(character..'.animation.frameName')
        end
    end
    if string.find(xml,'0000',0,true) then
        xml = string.sub(xml,0,string.len(xml) - 3)
    end
    if frameRate == nil then
        frameRate = getProperty(character..'.animation.curAnim.frameRate')
        if character == 'dad' then
            frameRate = dadAnim[1][2]
        elseif character == 'boyfriend' then
            frameRate = bfAnim[1][2]
        elseif character == 'gf' then
            frameRate = gfAnim[1][2]
        end
    end
    if loop == nil then
        if character == 'dad' then
            loop = dadAnim[1][3]
        elseif character == 'boyfriend' then
            loop = bfAnim[1][3]
        elseif character == 'gf' then
            loop = gfAnim[1][3]
        else
            loop = getProperty(character..'.animation.curAnim.looped')
        end
    end
    if offsetX == nil then
        if character == 'dad' then
            offsetX = dadAnim[1][4]
        elseif character == 'boyfriend' then
            offsetX = bfAnim[1][4]
        elseif character == 'gf' then
            offsetX = gfAnim[1][4]
        else
            offsetX = getProperty(character..'.offset.x')
        end
    end
    if offsetY == nil then
        if character == 'dad' then
            offsetY = dadAnim[1][5]
        elseif character == 'boyfriend' then
            offsetY = bfAnim[1][5]
        elseif character == 'gf' then
            offsetY = gfAnim[1][5]
        else
            offsetY = getProperty(character..'.offset.y')
        end
    end
    addAnimationByPrefix(spriteAnim, name, xml, frameRate, loop)
    setProperty(spriteAnim..'.offset.x', offsetX)
    setProperty(spriteAnim..'.offset.y', offsetY)
end]]--


function onTweenCompleted(tag)
    if tag == 'boyfriendGhostBye' then
        removeLuaSprite('boyfriendGhost',true)
    elseif tag == 'dadGhostBye' then
        removeLuaSprite('dadGhost',true)
    elseif tag == 'gfGhostBye' then
        removeLuaSprite('gfGhost',true)
    end
end
";
}