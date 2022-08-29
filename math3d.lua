File = require("file")
Misc = require("misc")
local shellsort = require("shellsort")

local sqrt = math.sqrt
local floor = math.floor

Math3D = {}

local Vec3D = {
    x = 0,
    y = 0,
    z = 0,
    w = 1,
}
Math3D.Vec3D = Vec3D

function Vec3D:new(o, x, y, z, w)
    if not o then
        o = {
            x = x or 0,
            y = y or 0,
            z = z or 0,
            w = w or 1,
        }
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Get the dot product of two vectors
function Vec3D.dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

-- Get the cross product of two vectors
function Vec3D.cross(v1, v2)
    return Vec3D:new(nil,
        v1.y * v2.z - v1.z * v2.y,
        v1.z * v2.x - v1.x * v2.z,
        v1.x * v2.y - v1.y * v2.x
    )
end

-- Get the length of the vector
function Vec3D:length()
    return sqrt(self:dot(self))
end

-- Normalise the vector so that each component is between 0-1. This is done in-place.
function Vec3D:norm()
    -- We inline the length calculation to gain a speed boost
    local l = sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    self.x = self.x / l
    self.y = self.y / l
    self.z = self.z / l
end

local VEC3D_COMPONENT_INDEX_MAPPING = {'x', 'y', 'z'}
function Vec3D.component(i)
    return VEC3D_COMPONENT_INDEX_MAPPING[i]
end

function Vec3D:offsetAndScale(offset, scale)
    self.x = (self.x / self.w + offset.x) * scale.x
    self.y = (self.y / self.w + offset.y) * scale.y
    self.z = (self.z / self.w + offset.z) * scale.z
end

local VEC3D_OPERATOR_ACTIONS = {
    ['add'] = function (u, v) return {u.x + v.x, u.y + v.y, u.z - v.z} end,
    ['sub'] = function (u, v) return {u.x - v.x, u.y + v.y, u.z - v.z} end,
    ['mul'] = function (u, k) return {u.x * k  , u.y * k  , u.z * k  } end,
    ['div'] = function (u, k) return {u.x / k  , u.y / k  , u.z / k  } end,
    ['cml'] = function (u, v) return {u.x * v.x, u.y * v.y, u.z * v.z} end
}

function Vec3D.rpn(ops)
    local stack = {}
    local actions = {
        ['number'] = function (op) table.insert(stack, op) end,
        ['string'] = function (op)
            local op2 = table.remove(stack)
            local op1 = table.remove(stack)
            local x, y, z = unpack(VEC3D_OPERATOR_ACTIONS[op](op1, op2))
            table.insert(stack, {x = x, y = y, z = z})
        end,
        ['table'] = function (op) table.insert(stack, {x = op.x, y = op.y, z = op.z}) end
    }
    for _, op in ipairs(ops) do
        actions[type(op)](op)
    end
    local result = table.remove(stack)
    return Vec3D:new(nil, result.x, result.y, result.z)
end

function Vec3D.cml(u, v)
    return Vec3D:new(nil, unpack(VEC3D_OPERATOR_ACTIONS['cml'](u, v)))
end

function Vec3D.__add(u, v)
    return Vec3D:new(nil, unpack(VEC3D_OPERATOR_ACTIONS['add'](u, v)))
end

function Vec3D.__sub(u, v)
    return Vec3D:new(nil, unpack(VEC3D_OPERATOR_ACTIONS['sub'](u, v)))
end

function Vec3D.__mul(u, k)
    return Vec3D:new(nil, unpack(VEC3D_OPERATOR_ACTIONS['mul'](u, k)))
end

function Vec3D.__div(u, k)
    return Vec3D:new(nil, unpack(VEC3D_OPERATOR_ACTIONS['div'](u, k)))
end

function Vec3D.__eq(u, v)
    return u.x == v.x and
           u.y == v.y and
           u.z == v.z
end

function Vec3D:__tostring()
    return ("{%.8f, %.8f, %.8f}"):format(self.x, self.y, self.z)
end

local Colour = {
    r = 1,
    g = 1,
    b = 1,
    a = 1,
}
Math3D.Colour = Colour

function Colour:new(o, r, g, b, a)
    if not o then
        o = {
            r = r or 1,
            g = g or 1,
            b = b or 1,
            a = a or 1,
        }
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

local Triangle = {
    vertices = {
        Vec3D:new(),
        Vec3D:new(),
        Vec3D:new(),
    },
    normal = Vec3D:new(),
    colour = Colour:new()
}
Math3D.Triangle = Triangle

function Triangle:calcNorm()
    do local line1, line2 = Vec3D:new(), Vec3D:new()
        self.normal = Vec3D:new()
        line1.x = self.vertices[2].x - self.vertices[1].x
        line1.y = self.vertices[2].y - self.vertices[1].y
        line1.z = self.vertices[2].z - self.vertices[1].z

        line2.x = self.vertices[3].x - self.vertices[1].x
        line2.y = self.vertices[3].y - self.vertices[1].y
        line2.z = self.vertices[3].z - self.vertices[1].z

        self.normal.x = line1.y * line2.z - line1.z * line2.y
        self.normal.y = line1.z * line2.x - line1.x * line2.z
        self.normal.z = line1.x * line2.y - line1.y * line2.x
    end

    -- Inlining normalisation for a bit of a speed boost
    local l = sqrt(self.normal.x * self.normal.x + self.normal.y * self.normal.y + self.normal.z * self.normal.z)
    self.normal.x = self.normal.x / l
    self.normal.y = self.normal.y / l
    self.normal.z = self.normal.z / l
end

function Triangle:new(o, v1, v2, v3, r, g, b, a, calcNorm)
    if not o then
        o = {
            vertices = {
                v1 or Vec3D:new(),
                v2 or Vec3D:new(),
                v3 or Vec3D:new(),
            },
            colour = Colour:new(nil, r, g, b, a)
        }
    end
    setmetatable(o, self)
    self.__index = self
    -- If calcNorm isn't provided or calcNorm is provided and is truthy, then we will
    -- run calcNorm
    if calcNorm == nil or calcNorm then o:calcNorm() end
    return o
end

-- Setter for first vertex of triangle. This will recalculate the normal for the triangle.
function Triangle:setVec1(v1, x, y, z, w)
    self.vertices[1] = v1 or Vec3D:new(nil,
        x or self.vertices[1].x,
        y or self.vertices[1].y,
        z or self.vertices[1].z,
        w or self.vertices[1].w
    )
    self:calcNorm()
end

-- Setter for second vertex of triangle. This will recalculate the normal for the triangle.
function Triangle:setVec2(v2, x, y, z, w)
    self.vertices[2] = v2 or Vec3D:new(nil,
        x or self.vertices[2].x,
        y or self.vertices[2].y,
        z or self.vertices[2].z,
        w or self.vertices[2].w
    )
    self:calcNorm()
end

-- Setter for third vertex of triangle. This will recalculate the normal for the triangle.
function Triangle:setVec3(v3, x, y, z, w)
    self.vertices[3] = v3 or Vec3D:new(nil,
        x or self.vertices[3].x,
        y or self.vertices[3].y,
        z or self.vertices[3].z,
        w or self.vertices[3].w
    )
    self:calcNorm()
end

-- Setter for all vertices of the triangle. This will recalculate the normal for the triangle
-- after setting all vertices.
function Triangle:setVecs(v1, v2, v3)
    self.vertices[1] = v1 or self.vertices[1]
    self.vertices[2] = v2 or self.vertices[2]
    self.vertices[3] = v3 or self.vertices[3]
    self:calcNorm()
end

-- Setter for each individual component of each vertex of the triangle. This will recalculate the normal
-- for the triangle after setting all provided components.
function Triangle:setVecComponents(
    x1, y1, z1, w1,
    x2, y2, z2, w2,
    x3, y3, z3, w3
)
    self.vertices[1].x = x1 or self.vertices[1].x
    self.vertices[1].y = y1 or self.vertices[1].y
    self.vertices[1].z = z1 or self.vertices[1].z
    self.vertices[1].w = w1 or self.vertices[1].w

    self.vertices[2].x = x2 or self.vertices[2].x
    self.vertices[2].y = y2 or self.vertices[2].y
    self.vertices[2].z = z2 or self.vertices[2].z
    self.vertices[2].w = w2 or self.vertices[2].w

    self.vertices[3].x = x3 or self.vertices[3].x
    self.vertices[3].y = y3 or self.vertices[3].y
    self.vertices[3].z = z3 or self.vertices[3].z
    self.vertices[3].w = w3 or self.vertices[3].w

    self:calcNorm()
end

function Triangle:offsetAndScale(offset, scale)
    self.vertices[1]:offsetAndScale(offset, scale)
    self.vertices[2]:offsetAndScale(offset, scale)
    self.vertices[3]:offsetAndScale(offset, scale)
    self:calcNorm()
end

function Triangle:calcColourFromLight(directionLight)
    local dp = self.normal.x * directionLight.directionNorm.x +
               self.normal.y * directionLight.directionNorm.y +
               self.normal.z * directionLight.directionNorm.z
    self.colour.r = dp
    self.colour.g = dp
    self.colour.b = dp
end

function Triangle:addVertex(vert)
    if #self.vertices < 3 then
        table.insert(self.vertices, vert)
    end
end

function Triangle:isFacingCamera(camera)
    -- Inline the operations so that they are a bit faster
    local x2, y2, z2 = self.vertices[1].x - camera.pos.x, self.vertices[1].y - camera.pos.y, self.vertices[1].z - camera.pos.z
    return self.normal.x * x2 + self.normal.y * y2 + self.normal.z * z2 < 0.0
end

function Triangle.__eq(tri1, tri2)
    return tri1.vertices[1] == tri2.vertices[1] and
           tri1.vertices[2] == tri2.vertices[2] and
           tri1.vertices[3] == tri2.vertices[3]
end

function Triangle:__tostring()
    return ("{%s, %s, %s}"):format(self.vertices[1]:__tostring(), self.vertices[2]:__tostring(), self.vertices[3]:__tostring())
end

local Mesh = {
    triangles = {},
    triangleLookup = {},
    mesh = nil,
    isFinalised = function () return false end
}
Math3D.Mesh = Mesh

function Mesh:new(o, path, batchUsage)
    o = o or {triangles = {}, triangleLookup = {}}
    setmetatable(o, self)
    self.__index = self
    if path then
        local pathExtension = File.getFileExtension(path)
        if pathExtension == '.obj' then
            o:loadFromOBJ(path, batchUsage)
        else
            error"Don't recognise extension: %s":format(pathExtension)
        end
    end
    return o
end

-- Adds a triangle to the mesh. This can only be done if the mesh is not finalised.
function Mesh:addTriangle(tri)
    if not self:isFinalised() then
        -- We create a mapping for the 3 new vertices of the triangle to the current index of the triangles array
        self.triangleLookup[3 * #self.triangles - 2] = #self.triangles
        self.triangleLookup[3 * #self.triangles - 1] = #self.triangles
        self.triangleLookup[3 * #self.triangles    ] = #self.triangles
        table.insert(self.triangles, tri)
    end
end

-- Sets the triangle at the given index to the given value. If the mesh is finalised then the corresponding vertices
-- will also be set.
function Mesh:setTriangle(i, tri)
    self.triangleLookup[3 * i - 2] = i
    self.triangleLookup[3 * i - 1] = i
    self.triangleLookup[3 * i    ] = i
    self.triangles[i] = tri
    if self:isFinalised() then
        self.mesh:setVertex(3 * i - 2, tri.vertices[1].x, tri.vertices[1].y, 0, 0, tri.colour.r, tri.colour.g, tri.colour.b, tri.colour.a)
        self.mesh:setVertex(3 * i - 1, tri.vertices[2].x, tri.vertices[2].y, 0, 0, tri.colour.r, tri.colour.g, tri.colour.b, tri.colour.a)
        self.mesh:setVertex(3 * i    , tri.vertices[3].x, tri.vertices[3].y, 0, 0, tri.colour.r, tri.colour.g, tri.colour.b, tri.colour.a)
    end
end

-- Instantiates the love.graphics.Mesh that the logical mesh will be drawn to. This should be called when there
-- are no more triangles to add. Triangles can still be set though.
function Mesh:finalise(batchUsage)
    self.isFinalised = function () return true end
    local vertices = {}
    for i=1, #self.triangles do
        table.insert(vertices, {self.triangles[i].vertices[1].x, self.triangles[i].vertices[1].y})
        table.insert(vertices, {self.triangles[i].vertices[2].x, self.triangles[i].vertices[2].y})
        table.insert(vertices, {self.triangles[i].vertices[3].x, self.triangles[i].vertices[3].y})
    end
    self.mesh = love.graphics.newMesh(vertices, 'triangles', batchUsage)
end

function Mesh:loadFromOBJ(path, batchUsage)
    local verts = {}
    for _, line in ipairs(File.readFileLines(path)) do
        if line:sub(1, 1) == 'v' then
            local vert, i = Vec3D:new(), 1
            for w in line:gmatch("%S+") do
                if i > 1 then
                    vert[Vec3D.component(i - 1)] = tonumber(w)
                end
                i = i + 1
            end
            print('adding:', vert)
            table.insert(verts, vert)
        elseif line:sub(1, 1) == 'f' then
            local indices, i = {}, 1
            for w in line:gmatch("%S+") do
                if i > 1 then
                    table.insert(indices, tonumber(w))
                end
                i = i + 1
            end
            print('triangle vertex 1:', verts[indices[1]], indices[1])
            print('triangle vertex 2:', verts[indices[2]], indices[2])
            print('triangle vertex 3:', verts[indices[3]], indices[3])
            local tri = Triangle:new(nil,
                verts[indices[1]],
                verts[indices[2]],
                verts[indices[3]]
            )
            self:addTriangle(tri)
        end
    end
    if batchUsage then
        print("finalising...")
        self:finalise(batchUsage)
    end
    return true
end

function Mesh:setVertexMap(vertexMap)
    if self:isFinalised() then
        -- We sort the vertex map by the midpoints of each triangle. This implements the painter's algorithm
        -- table.sort(vertexMap, function (vi1, vi2)
        --     local ti1, ti2 = self.triangleLookup[vi1], self.triangleLookup[vi2]
        --     if ti1 ~= ti2 then
        --         local t1, t2 = self.triangles[ti1], self.triangles[ti2]
        --         return (t1.vertices[1].z + t1.vertices[2].z + t1.vertices[3].z) / 3.0 >
        --                (t2.vertices[1].z + t2.vertices[2].z + t2.vertices[3].z) / 3.0
        --     end
        --     return vi1 < vi2
        -- end)
        vertexMap = shellsort(vertexMap, function (vi1, vi2)
            local ti1, ti2 = self.triangleLookup[vi1], self.triangleLookup[vi2]
            if ti1 ~= ti2 then
                local t1, t2 = self.triangles[ti1], self.triangles[ti2]
                return (t1.vertices[1].z + t1.vertices[2].z + t1.vertices[3].z) / 3.0 >
                       (t2.vertices[1].z + t2.vertices[2].z + t2.vertices[3].z) / 3.0
            end
            return vi1 < vi2
        end)
        self.mesh:setVertexMap(vertexMap)
    end
end

function Mesh:__tostring()
    local s = '{'
    for i, triangle in ipairs(self.triangles) do
        s = s .. triangle:__tostring()
        if i ~= #self.triangles then
            s = s .. ', '
        end
    end
    return s
end

local Matrix = {
    matrix = {},
    n = 0,
    m = 0,
    k = 0,
}
Math3D.Matrix = Matrix

function Matrix:_init()
    self.matrix = {}
    for i=1, self.n do
        -- create a new row
        self.matrix[i] = {}
        for j=1, self.m do
            self.matrix[i][j] = self.k
        end
    end
end

function Matrix:new(o, n, m, k)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.n = n or 4
    o.m = m or 4
    o.k = k or 0
    o:_init()
    return o
end

function Matrix:set(n, m, v)
    self.matrix[n][m] = v
end

function Matrix:multiplyVec3D(i)
    if self.n == 4 and self.m == 4 then
        return Vec3D:new(nil,
            i.x * self.matrix[1][1] + i.y * self.matrix[2][1] + i.z * self.matrix[3][1] + i.w * self.matrix[4][1],
            i.x * self.matrix[1][2] + i.y * self.matrix[2][2] + i.z * self.matrix[3][2] + i.w * self.matrix[4][2],
            i.x * self.matrix[1][3] + i.y * self.matrix[2][3] + i.z * self.matrix[3][3] + i.w * self.matrix[4][3],
            i.x * self.matrix[1][4] + i.y * self.matrix[2][4] + i.z * self.matrix[3][4] + i.w * self.matrix[4][4]
        )
    end
    error("Cannot multiply %dx%d matrix by Vec3D, has to be 4x4"):format(self.n, self.m)
end

function Matrix.makeRotationX(fAngleRad)
    local matrix = Matrix:new(nil, 4, 4)
    matrix:set(1, 1, 1.0)
    matrix:set(2, 2, math.cos(fAngleRad))
    matrix:set(2, 3, math.sin(fAngleRad))
    matrix:set(3, 2, -math.sin(fAngleRad))
    matrix:set(3, 3, math.cos(fAngleRad))
    matrix:set(4, 4, 1.0)
    return matrix
end

function Matrix.makeRotationY(fAngleRad)
    local matrix = Matrix:new(nil, 4, 4)
    matrix:set(1, 1, math.cos(fAngleRad))
    matrix:set(1, 3, math.sin(fAngleRad))
    matrix:set(3, 1, -math.sin(fAngleRad))
    matrix:set(2, 2, 1.0)
    matrix:set(3, 3, math.cos(fAngleRad))
    matrix:set(4, 4, 1.0)
    return matrix
end

function Matrix.makeRotationZ(fAngleRad)
    local matrix = Matrix:new(nil, 4, 4)
    matrix:set(1, 1, math.cos(fAngleRad))
    matrix:set(1, 2, math.sin(fAngleRad))
    matrix:set(2, 1, -math.sin(fAngleRad))
    matrix:set(2, 2, math.cos(fAngleRad))
    matrix:set(3, 3, 1.0)
    matrix:set(4, 4, 1.0)
    return matrix
end

function Matrix.makeTranslation(x, y, z)
    local matrix = Matrix:new(nil, 4, 4)
    matrix:set(1, 1, 1.0)
    matrix:set(2, 2, 1.0)
    matrix:set(3, 3, 1.0)
    matrix:set(4, 4, 1.0)
    matrix:set(4, 1, x)
    matrix:set(4, 2, y)
    matrix:set(4, 3, z)
    return matrix
end

function Matrix.__mul(m1, m2)
    if m1.n == m2.n and m1.m == m2.m then
        local matrix = Matrix:new(nil, m1.n, m1.m)
        for c = 1, m1.m do
            for r = 1, m1.n do
                matrix:set(r, c,
                    m1.matrix[r][1] * m2.matrix[1][c] +
                    m1.matrix[r][2] * m2.matrix[2][c] +
                    m1.matrix[r][3] * m2.matrix[3][c] +
                    m1.matrix[r][4] * m2.matrix[4][c]
                )
            end
        end
        return matrix
    end
    error("Cannot multiply %dx%d matrix by %dx%d matrix. Must be same dims."):format(m1.n, m1.m, m2.n, m2.m)
end

function Matrix:__tostring()
    local s = ''
    for i=1, self.n do
        local row = ''
        for j=1, self.m do
            row = row .. self.matrix[i][j]
            if j ~= self.m then
                row = row .. '\t'
            end
        end
        s = s .. row
        if i ~= self.n then
            s = s .. '\n'
        end
    end
    return s
end

local Camera = {
    pos = Vec3D:new(),
    near = 0.1,
    far = 1000.0,
    fov = 90.0,
    fov_rad = nil,
    width = 800,
    height = 600,
    proj = nil,
    aspect_ratio = nil,
}
Math3D.Camera = Camera

function Camera:recalcProjMat()
    self.proj:set(1, 1, self.aspect_ratio * self.fov_rad)
    self.proj:set(2, 2, self.fov_rad)
    self.proj:set(3, 3, self.far / (self.far - self.near))
    self.proj:set(4, 3, (-self.far * self.near) / (self.far - self.near))
    self.proj:set(3, 4, 1.0)
    self.proj:set(4, 4, 0.0)
end

function Camera:new(o, x, y, z, near, far, fov, width, height)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.pos = Vec3D:new(nil, x or 0, y or 0, z or 0)
    o.near = near or 0.1
    o.far = far or 1000.0
    o.fov = fov or 90.0
    o.fov_rad = math.rad(self.fov)
    o.width = width or 800
    o.height = height or 600
    o.proj = Matrix:new()
    o.aspect_ratio = self.height / self.width
    o:recalcProjMat()
    return o
end

local DirectionLight = {
    direction = Vec3D:new(),
    directionNorm = Vec3D:new()
}
Math3D.DirectionLight = DirectionLight

function DirectionLight:calcNorm()
    self.directionNorm.x = self.direction.x
    self.directionNorm.y = self.direction.y
    self.directionNorm.z = self.direction.z
    -- Inlining normalisation for a bit of a speed boost
    local l = sqrt(
        self.directionNorm.x * self.directionNorm.x +
        self.directionNorm.y * self.directionNorm.y +
        self.directionNorm.z * self.directionNorm.z
    )
    self.directionNorm.x = self.directionNorm.x / l
    self.directionNorm.y = self.directionNorm.y / l
    self.directionNorm.z = self.directionNorm.z / l
end

function DirectionLight:new(o, x, y, z)
    o = o or {
        direction = Vec3D:new(),
        directionNorm = Vec3D:new()
    }
    setmetatable(o, self)
    self.__index = self
    o.direction.x = x or 0
    o.direction.y = y or 0
    o.direction.z = z or 0
    o:calcNorm()
    return o
end

function DirectionLight:set(x, y, z)
    self.direction.x = x or self.direction.x
    self.direction.y = y or self.direction.y
    self.direction.z = z or self.direction.z
    self:calcNorm()
end


return Math3D
