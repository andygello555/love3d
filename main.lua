Math3D = require("math3d")
Misc = require("misc")
Data = require("data")
File = require("file")

local mesh = Math3D.Mesh:new()
local camera = Math3D.Camera:new()
local light = Math3D.DirectionLight:new(nil, 0.0, 0.0, -1.0)
local shader = love.graphics.newShader(File.readFile("shaders/pixel.glsl"), File.readFile("shaders/vertex.glsl"))
-- WIREFRAMES = true


function love.load()
    mesh = Math3D.Mesh:new(nil, "assets/models/teapot.obj")
end

local matRotX = Math3D.Matrix:new()
local matRotZ = Math3D.Matrix:new()
local matTrans = Math3D.Matrix:new()
local matWorld = Math3D.Matrix:new()
local meshProjected = Math3D.Mesh:new()
local pause = false
local vertexMap = {}
local fTheta = 0.0

function love.update(dt)
    if not pause then
        fTheta = fTheta + 1.0 * -dt
    end

    matRotZ = Math3D.Matrix.makeRotationZ(fTheta * 0.5)
    matRotX = Math3D.Matrix.makeRotationX(fTheta)

    matTrans = Math3D.Matrix.makeTranslation(0.0, 0.0, 10.0)

    matWorld = matRotZ * matRotX
    matWorld = matWorld * matTrans

    vertexMap = {}
    for i, triangle in ipairs(mesh.triangles) do
        local triTransformed = Math3D.Triangle:new(nil,
            matWorld:multiplyVec3D(triangle.vertices[1]),
            matWorld:multiplyVec3D(triangle.vertices[2]),
            matWorld:multiplyVec3D(triangle.vertices[3])
        )

        if triTransformed:isFacingCamera(camera) then
            table.insert(vertexMap, 3 * i - 2)
            table.insert(vertexMap, 3 * i - 1)
            table.insert(vertexMap, 3 * i    )
        end

        triTransformed:calcColourFromLight(light)

        -- Project the rotated and translated triangle vertices onto the screen using the camera's projection matrix
        local triProjected = Math3D.Triangle:new(nil,
            camera.proj:multiplyVec3D(triTransformed.vertices[1]),
            camera.proj:multiplyVec3D(triTransformed.vertices[2]),
            camera.proj:multiplyVec3D(triTransformed.vertices[3]),
            triTransformed.colour.r, triTransformed.colour.g, triTransformed.colour.b, triTransformed.colour.a
        )

        triProjected.vertices[1] = triProjected.vertices[1] / triProjected.vertices[1].w
        triProjected.vertices[2] = triProjected.vertices[2] / triProjected.vertices[2].w
        triProjected.vertices[3] = triProjected.vertices[3] / triProjected.vertices[3].w

        -- Offset vertices from -1.0 to 1.0 into 0.0 to 2.0
        local offsetViewVec = Math3D.Vec3D:new(nil, 1, 1, 0)
        triProjected.vertices[1] = triProjected.vertices[1] + offsetViewVec
        triProjected.vertices[2] = triProjected.vertices[2] + offsetViewVec
        triProjected.vertices[3] = triProjected.vertices[3] + offsetViewVec

        -- Scale vertices into range 0 to WINDOW_WIDTH and 0 to WINDOW_HEIGHT
        triProjected.vertices[1].x = triProjected.vertices[1].x * 0.5 * love.graphics.getWidth()
        triProjected.vertices[1].y = triProjected.vertices[1].y * 0.5 * love.graphics.getHeight()

        triProjected.vertices[2].x = triProjected.vertices[2].x * 0.5 * love.graphics.getWidth()
        triProjected.vertices[2].y = triProjected.vertices[2].y * 0.5 * love.graphics.getHeight()

        triProjected.vertices[3].x = triProjected.vertices[3].x * 0.5 * love.graphics.getWidth()
        triProjected.vertices[3].y = triProjected.vertices[3].y * 0.5 * love.graphics.getHeight()

        meshProjected:setTriangle(i, triProjected)
    end

    if not meshProjected:isFinalised() then
        meshProjected:finalise('stream')
    end
    meshProjected:setVertexMap(vertexMap)
end

function love.keypressed(key, scancode, isRepeat)
    if scancode == "space" then
        pause = not pause
    end
end

function love.draw()
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    -- love.graphics.print("vertexMap: " .. Misc.tprint(vertexMap) .. " " .. #vertexMap .. " " .. tostring(#vertexMap % 3 == 0) .. " " .. tostring(meshProjected.mesh:getVertexCount()), 10, 20)
    -- meshProjected.mesh:setVertexMap(1, 2, 3)
    love.graphics.setShader(shader)
    love.graphics.draw(meshProjected.mesh)
    if WIREFRAMES then
        love.graphics.setColor(0.0, 0.0, 0.0, 1.0)
        for i = 1, #vertexMap, 3 do
            local vIndex = vertexMap[i]
            local x1, y1 = meshProjected.mesh:getVertex(vIndex)
            local x2, y2 = meshProjected.mesh:getVertex(vIndex + 1)
            local x3, y3 = meshProjected.mesh:getVertex(vIndex + 2)
            love.graphics.polygon("line", {
                x1, y1,
                x2, y2,
                x3, y3,
            })
        end
        love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    end

    love.graphics.setShader()
end
