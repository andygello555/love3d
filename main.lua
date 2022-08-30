Vec3D = require("math3d").Vec3D
Matrix = require("math3d").Matrix
Mesh = require("math3d").Mesh
Camera = require("math3d").Camera
DirectionLight = require("math3d").DirectionLight
Triangle = require("math3d").Triangle
Misc = require("misc")
Data = require("data")
File = require("file")


local mesh = Mesh:new()
local camera = Camera:new()
local light = DirectionLight:new(nil, 0.0, 0.0, -1.0)
local shader = love.graphics.newShader(File.readFile("shaders/pixel.glsl"), File.readFile("shaders/vertex.glsl"))
local canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
-- WIREFRAMES = true
-- PROFILING = true


function love.load()
    if PROFILING then
        love.profiler = require('profile')
        love.profiler.start()
    end
    mesh = Mesh:new(nil, "assets/models/teapot.obj")
    print("vertices in mesh:", #mesh.triangles * 3)
end


local matRotX = Matrix:new()
local matRotZ = Matrix:new()
local matTrans = Matrix:new()
local matWorld = Matrix:new()
local meshProjected = Mesh:new()
local pause = false
local fTheta = 0.0
love.frame = 0


function love.update(dt)
    if not pause then
        fTheta = fTheta + 1.0 * -dt
    end

    matRotZ = Matrix.makeRotationZ(fTheta * 0.5)
    matRotX = Matrix.makeRotationX(fTheta)

    matTrans = Matrix.makeTranslation(0.0, 0.0, 10.0)

    matWorld = matRotZ * matRotX
    matWorld = matWorld * matTrans

    meshProjected:resetVertexMap()
    for i, triangle in ipairs(mesh.triangles) do
        local triTransformed = Triangle:new(nil,
            triangle.vertices[1],
            triangle.vertices[2],
            triangle.vertices[3],
            nil, nil, nil, nil, false
        )
        triTransformed:multiplyVecsByMatrix(matWorld, true)
        -- local triTransformed = Triangle:new(nil,
        --     matWorld:multiplyVec3D(triangle.vertices[1]),
        --     matWorld:multiplyVec3D(triangle.vertices[2]),
        --     matWorld:multiplyVec3D(triangle.vertices[3])
        -- )

        -- isFacingCamera and calcColourFromLight both use the transformed world normals of the current triangle.
        -- We don't have to calculate or pass any normals to any subsequent triangle constructors
        local addVertexMap = triTransformed:isFacingCamera(camera)
        triTransformed:calcColourFromLight(light)

        -- Project the rotated and translated triangle vertices onto the screen using the camera's projection matrix
        -- local triProjected = Triangle:new(nil,
        --     camera.proj:multiplyVec3D(triTransformed.vertices[1]),
        --     camera.proj:multiplyVec3D(triTransformed.vertices[2]),
        --     camera.proj:multiplyVec3D(triTransformed.vertices[3]),
        --     triTransformed.colour.r, triTransformed.colour.g, triTransformed.colour.b, triTransformed.colour.a, false
        -- )
        local triProjected = Triangle:new(nil,
            triTransformed.vertices[1],
            triTransformed.vertices[2],
            triTransformed.vertices[3],
            triTransformed.colour.r, triTransformed.colour.g, triTransformed.colour.b, triTransformed.colour.a, false
        )
        triProjected:multiplyVecsByMatrix(camera.proj)
        meshProjected:setTriangle(i, triProjected, addVertexMap)
    end

    if not meshProjected:isFinalised() then
        meshProjected:finalise('stream')
    end
    meshProjected:setVertexMap()

    love.frame = love.frame + 1
    if PROFILING and love.frame % 10 == 0 then
        print(love.profiler.report(100))
        love.profiler.reset()
    end

    -- Rectangle is drawn to the canvas with the regular alpha blend mode.
    love.graphics.setCanvas(canvas)
        love.graphics.setShader(shader)
            love.graphics.clear()
            love.graphics.setBlendMode("alpha")
            love.graphics.draw(meshProjected.mesh)
        love.graphics.setShader()
    love.graphics.setCanvas()
end

function love.keypressed(key, scancode, isRepeat)
    if scancode == "space" then
        pause = not pause
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print("Frames: " .. love.frame, 10, 20)
    love.graphics.print("Vertices being shown: " .. #meshProjected.vertexMap .. "/" .. #meshProjected.triangles * 3 .. (" %.2f%%"):format(#meshProjected.vertexMap / (#meshProjected.triangles * 3) * 100), 10, 30)
    -- love.graphics.print("vertexMap: " .. Misc.tprint(vertexMap) .. " " .. #vertexMap .. " " .. tostring(#vertexMap % 3 == 0) .. " " .. tostring(meshProjected.mesh:getVertexCount()), 10, 20)
    -- meshProjected.mesh:setVertexMap(1, 2, 3)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(canvas)
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
end
