Bridge = Bridge or {}
peds = {}

local fwName = 'standalone'
local QBCore, ESX = nil, nil

local pending = {}
local cbId = 0

local function detectFramework()
    if Config.Framework == 'qb' or
        (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        fwName = 'qb'
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then QBCore = obj end
        return
    end

    if Config.Framework == 'esx' or
        (Config.Framework == 'auto' and GetResourceState('es_extended') ==
            'started') then
        fwName = 'esx'
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok then ESX = obj end
        return
    end

    fwName = 'standalone'
end

detectFramework()

function Bridge.Framework() return fwName end

function Bridge.Notify(message, nType, duration)
    if fwName == 'qb' and QBCore and QBCore.Functions and
        QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, nType or 'primary', duration or 5000)
        return
    end
    if fwName == 'esx' and ESX and ESX.ShowNotification then
        ESX.ShowNotification(message)
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, duration or 5000)
end

function Bridge.ShowHelp(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function Bridge.HideHelp() ClearAllHelpMessages() end

function Bridge.Callback(name, cb, ...)
    cbId = cbId + 1
    local id = cbId
    pending[id] = cb
    TriggerServerEvent('pug-pawnshop:server:callback', id, name, ...)

    local timeoutMs = (Config and Config.Security and
                          Config.Security.callbackTimeoutMs) or 0
    if timeoutMs > 0 then
        SetTimeout(timeoutMs, function()
            local fn = pending[id]
            if not fn then return end
            pending[id] = nil
            fn(nil, 'timeout')
        end)
    end
end

local camera = nil
function waitForContextMenu()
    local maxAttempts = 40
    local attemptInterval = 1
    local counter = 0

    while true do
        Wait(attemptInterval)
        SetEntityLocallyInvisible(PlayerPedId())
        if Config.Menu == "lation_ui" and not exports.lation_ui:getOpenMenu() or Config.Menu == "ox_lib" and not lib.getOpenContextMenu() or not IsNuiFocused() then
            counter = counter + 1
            if counter >= maxAttempts then
                ExecuteCommand('togglehud')
				RemoveCamera()
                break
            end
        else
            counter = 0
        end
    end
end
function CreateCameraNPC(entity, offset)
    local offset = offset or {0.0,0.0,0.0}

	SetPedTalk(entity)
    PlayAmbientSpeech1(entity, 'GENERIC_HI', 'SPEECH_PARAMS_STANDARD')

	CreateThread(function()
		waitForContextMenu()
	end)

    if not DoesEntityExist(entity) then
        print("Entity does not exist.")
        return
    end

    local coords = GetOffsetFromEntityInWorldCoords(entity, offset[1], offset[2], offset[3])
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    SetCamCoord(cam, coords.x, coords.y, coords.z)
    SetCamRot(cam, 0.0, 0.0, GetEntityHeading(entity) - 195, 0)
    SetCamFov(cam, 60.0)
    camera = cam
end 

function CreateCameraCoord(coord, offset, rotation)
    if not coord or type(coord) ~= "table" then return end

    local offset = offset or {0.0, 0.0, 0.0}
    local rotation = rotation or {0.0, 0.0, 0.0}

    -- Apply heading rotation to offset
    local heading = coord[4] or 0.0
    local hRad = math.rad(heading)
    local ox, oy = offset[1] or 0.0, offset[2] or 0.0
    local rx = ox * math.cos(hRad) - oy * math.sin(hRad)
    local ry = ox * math.sin(hRad) + oy * math.cos(hRad)

    local camX = coord[1] + rx
    local camY = coord[2] + ry
    local camZ = coord[3] + (offset[3] or 0.0)

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, camX, camY, camZ)
    SetCamRot(cam, rotation[1], rotation[2], rotation[3], 2)
    SetCamFov(cam, 60.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)

    camera = cam
end
function RemoveCamera()
    if camera then
        -- Transition back to gameplay cam smoothly
        local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        local playerPed = PlayerPedId()
        local coords = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(2)

        SetCamCoord(cam, coords.x, coords.y, coords.z)
        SetCamRot(cam, rot.x, rot.y, rot.z, 2)
        SetCamFov(cam, GetGameplayCamFov())
        SetCamActive(cam, true)

        SetCamActiveWithInterp(cam, camera, 800, 1, 1) -- smooth transition
        CreateThread(function()
            Wait(800)
            RenderScriptCams(false, true, 500, true, true)
            DestroyCam(camera, true)
            DestroyCam(cam, true)
            camera = nil
        end)
    end
end

RegisterNetEvent('pug-pawnshop:client:callback', function(id, result, err)
    local fn = pending[id]
    if not fn then return end
    pending[id] = nil
    fn(result, err)
end)
