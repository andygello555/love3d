File = require("file")
Misc = require("misc")

Math3D = {}

Math3D.Vec3D = {
    x = 0,
    y = 0,
    z = 0,
    w = 1,
}

function Math3D.Vec3D:new(o, x, y, z, w)
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
function Math3D.Vec3D.dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

-- Get the cross product of two vectors
function Math3D.Vec3D.cross(v1, v2)
    return Math3D.Vec3D:new(nil,
        v1.y * v2.z - v1.z * v2.y,
        v1.z * v2.x - v1.x * v2.z,
        v1.x * v2.y - v1.y * v2.x
    )
end

-- Get the length of the vector
function Math3D.Vec3D:length()
    return math.sqrt(self:dot(self))
end

-- Normalise the vector so that each component is between 0-1. This is done in-place.
function Math3D.Vec3D:norm()
    local l = self:length()
    -- print(self, l)
    self.x = self.x / l
    self.y = self.y / l
    self.z = self.z / l
end

local VEC3D_COMPONENT_INDEX_MAPPING = {'x', 'y', 'z'}
function Math3D.Vec3D.component(i)
    return VEC3D_COMPONENT_INDEX_MAPPING[i]
end

function Math3D.Vec3D.__add(u, v)
    return Math3D.Vec3D:new(nil, u.x + v.x, u.y + v.y, u.z - v.z)
end

function Math3D.Vec3D.__sub(u, v)
    return Math3D.Vec3D:new(nil, u.x - v.x, u.y - v.y, u.z - v.z)
end

function Math3D.Vec3D.__mul(u, k)
    return Math3D.Vec3D:new(nil, u.x * k, u.y * k, u.z * k)
end

function Math3D.Vec3D.__div(u, k)
    return Math3D.Vec3D:new(nil, u.x / k, u.y / k, u.z / k)
end

function Math3D.Vec3D.__eq(u, v)
    return u.x == v.x and
           u.y == v.y and
           u.z == v.z
end

function Math3D.Vec3D:__tostring()
    return ("{%.8f, %.8f, %.8f}"):format(self.x, self.y, self.z)
end

Math3D.Colour = {
    r = 1,
    g = 1,
    b = 1,
    a = 1,
}

function Math3D.Colour:new(o, r, g, b, a)
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

Math3D.Triangle = {
    vertices = {
        Math3D.Vec3D:new(),
        Math3D.Vec3D:new(),
        Math3D.Vec3D:new(),
    },
    normal = Math3D.Vec3D:new(),
    colour = Math3D.Colour:new()
}

function Math3D.Triangle:calcNorm()
    local line1, line2 = Math3D.Vec3D:new(), Math3D.Vec3D:new()
    self.normal = Math3D.Vec3D:new()
    line1.x = self.vertices[2].x - self.vertices[1].x
    line1.y = self.vertices[2].y - self.vertices[1].y
    line1.z = self.vertices[2].z - self.vertices[1].z

    line2.x = self.vertices[3].x - self.vertices[1].x
    line2.y = self.vertices[3].y - self.vertices[1].y
    line2.z = self.vertices[3].z - self.vertices[1].z

    self.normal.x = line1.y * line2.z - line1.z * line2.y
    self.normal.y = line1.z * line2.x - line1.x * line2.z
    self.normal.z = line1.x * line2.y - line1.y * line2.x

    self.normal:norm()
end

function Math3D.Triangle:new(o, v1, v2, v3, r, g, b, a)
    if not o then
        o = {
            vertices = {
                v1 or Math3D.Vec3D:new(),
                v2 or Math3D.Vec3D:new(),
                v3 or Math3D.Vec3D:new(),
            },
            colour = Math3D.Colour:new(nil, r, g, b, a)
        }
    end
    setmetatable(o, self)
    self.__index = self
    o:calcNorm()
    return o
end

function Math3D.Triangle:calcColourFromLight(directionLight)
    self:calcNorm()
    directionLight:calcNorm()
    local dp = self.normal:dot(directionLight.directionNorm)
    self.colour.r = dp
    self.colour.g = dp
    self.colour.b = dp
end

function Math3D.Triangle:addVertex(vert)
    if #self.vertices < 3 then
        table.insert(self.vertices, vert)
    end
end

function Math3D.Triangle:isFacingCamera(camera)
    self:calcNorm()
    return self.normal:dot(self.vertices[1] - camera.pos) < 0.0
end

function Math3D.Triangle.__eq(tri1, tri2)
    for i = 1, 3 do
        if tri1.vertices[i] ~= tri2.vertices[i] then
            return false
        end
    end
    return true
end

function Math3D.Triangle:__tostring()
    return ("{%s, %s, %s}"):format(self.vertices[1]:__tostring(), self.vertices[2]:__tostring(), self.vertices[3]:__tostring())
end

Math3D.Mesh = {
    triangles = {},
    mesh = nil,
    isFinalised = function () return false end
}

function Math3D.Mesh:new(o, path, batchUsage)
    o = o or {triangles = {}}
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
function Math3D.Mesh:addTriangle(tri)
    if not self:isFinalised() then
        table.insert(self.triangles, tri)
    end
end

-- Sets the triangle at the given index to the given value. If the mesh is finalised then the corresponding vertices
-- will also be set.
function Math3D.Mesh:setTriangle(i, tri)
    self.triangles[i] = tri
    if self:isFinalised() then
        self.mesh:setVertex(3 * i - 2, tri.vertices[1].x, tri.vertices[1].y, 0, 0, tri.colour.r, tri.colour.g, tri.colour.b, tri.colour.a)
        self.mesh:setVertex(3 * i - 1, tri.vertices[2].x, tri.vertices[2].y, 0, 0, tri.colour.r, tri.colour.g, tri.colour.b, tri.colour.a)
        self.mesh:setVertex(3 * i    , tri.vertices[3].x, tri.vertices[3].y, 0, 0, tri.colour.r, tri.colour.g, tri.colour.b, tri.colour.a)
    end
end

-- Instantiates the love.graphics.Mesh that the logical mesh will be drawn to. This should be called when there
-- are no more triangles to add. Triangles can still be set though.
function Math3D.Mesh:finalise(batchUsage)
    self.isFinalised = function () return true end
    local vertices = {}
    for _, triangle in ipairs(self.triangles) do
        for _, vertex in ipairs(triangle.vertices) do
            table.insert(vertices, {vertex.x, vertex.y})
        end
    end
    self.mesh = love.graphics.newMesh(vertices, 'triangles', batchUsage)
end

function Math3D.Mesh:loadFromOBJ(path, batchUsage)
    local verts = {}
    for _, line in ipairs(File.readFileLines(path)) do
        if line:sub(1, 1) == 'v' then
            local vert, i = Math3D.Vec3D:new(), 1
            for w in line:gmatch("%S+") do
                if i > 1 then
                    vert[Math3D.Vec3D.component(i - 1)] = tonumber(w)
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
            local tri = Math3D.Triangle:new(nil,
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

function Math3D.Mesh:setVertexMap(vertexMap)
    if self:isFinalised() then
        -- We sort the vertex map by the midpoints of each triangle. This implements the painter's algorithm
        table.sort(vertexMap, function (vi1, vi2)
            local t1 = self.triangles[math.floor((vi1 - 1) / 3) + 1]
            local t2 = self.triangles[math.floor((vi2 - 1) / 3) + 1]
			local z1 = (t1.vertices[1].z + t1.vertices[2].z + t1.vertices[3].z) / 3.0
			local z2 = (t2.vertices[1].z + t2.vertices[2].z + t2.vertices[3].z) / 3.0
            if z1 ~= z2 then return z1 > z2 end
			return vi1 < vi2
        end)
        self.mesh:setVertexMap(vertexMap)
    end
end

function Math3D.Mesh:__tostring()
    local s = '{'
    for i, triangle in ipairs(self.triangles) do
        s = s .. triangle:__tostring()
        if i ~= #self.triangles then
            s = s .. ', '
        end
    end
    return s
end

Math3D.Matrix = {
    matrix = {},
    n = 0,
    m = 0
}

function Math3D.Matrix:_init()
    self.matrix = {}
    for i=1, self.n do
        -- create a new row
        self.matrix[i] = {}
        for j=1, self.m do
            self.matrix[i][j] = self.k
        end
    end
end

function Math3D.Matrix:new(o, n, m, k)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.n = n or 4
    o.m = m or 4
    o.k = k or 0
    o:_init()
    return o
end

function Math3D.Matrix:set(n, m, v)
    self.matrix[n][m] = v
end

function Math3D.Matrix:multiplyVec3D(i)
    if self.n == 4 and self.m == 4 then
        local v = Math3D.Vec3D:new()
        v.x = i.x * self.matrix[1][1] + i.y * self.matrix[2][1] + i.z * self.matrix[3][1] + i.w * self.matrix[4][1];
        v.y = i.x * self.matrix[1][2] + i.y * self.matrix[2][2] + i.z * self.matrix[3][2] + i.w * self.matrix[4][2];
        v.z = i.x * self.matrix[1][3] + i.y * self.matrix[2][3] + i.z * self.matrix[3][3] + i.w * self.matrix[4][3];
        v.w = i.x * self.matrix[1][4] + i.y * self.matrix[2][4] + i.z * self.matrix[3][4] + i.w * self.matrix[4][4];
        return v;
    end
    error("Cannot multiply %dx%d matrix by Vec3D, has to be 4x4"):format(self.n, self.m)
end

function Math3D.Matrix.makeRotationX(fAngleRad)
    local matrix = Math3D.Matrix:new(nil, 4, 4)
    matrix:set(1, 1, 1.0)
    matrix:set(2, 2, math.cos(fAngleRad))
    matrix:set(2, 3, math.sin(fAngleRad))
    matrix:set(3, 2, -math.sin(fAngleRad))
    matrix:set(3, 3, math.cos(fAngleRad))
    matrix:set(4, 4, 1.0)
    return matrix
end

function Math3D.Matrix.makeRotationY(fAngleRad)
    local matrix = Math3D.Matrix:new(nil, 4, 4)
    matrix:set(1, 1, math.cos(fAngleRad))
    matrix:set(1, 3, math.sin(fAngleRad))
    matrix:set(3, 1, -math.sin(fAngleRad))
    matrix:set(2, 2, 1.0)
    matrix:set(3, 3, math.cos(fAngleRad))
    matrix:set(4, 4, 1.0)
    return matrix
end

function Math3D.Matrix.makeRotationZ(fAngleRad)
    local matrix = Math3D.Matrix:new(nil, 4, 4)
    matrix:set(1, 1, math.cos(fAngleRad))
    matrix:set(1, 2, math.sin(fAngleRad))
    matrix:set(2, 1, -math.sin(fAngleRad))
    matrix:set(2, 2, math.cos(fAngleRad))
    matrix:set(3, 3, 1.0)
    matrix:set(4, 4, 1.0)
    return matrix
end

function Math3D.Matrix.makeTranslation(x, y, z)
    local matrix = Math3D.Matrix:new(nil, 4, 4)
    matrix:set(1, 1, 1.0)
    matrix:set(2, 2, 1.0)
    matrix:set(3, 3, 1.0)
    matrix:set(4, 4, 1.0)
    matrix:set(4, 1, x)
    matrix:set(4, 2, y)
    matrix:set(4, 3, z)
    return matrix
end

function Math3D.Matrix.__mul(m1, m2)
    if m1.n == m2.n and m1.m == m2.m then
        local matrix = Math3D.Matrix:new(nil, m1.n, m1.m)
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

function Math3D.Matrix:__tostring()
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

Math3D.Camera = {
    pos = Math3D.Vec3D:new(),
    near = 0.1,
    far = 1000.0,
    fov = 90.0,
    fov_rad = nil,
    width = 800,
    height = 600,
    proj = nil,
    aspect_ratio = nil,
}

function Math3D.Camera:recalcProjMat()
    self.proj:set(1, 1, self.aspect_ratio * self.fov_rad)
    self.proj:set(2, 2, self.fov_rad)
    self.proj:set(3, 3, self.far / (self.far - self.near))
    self.proj:set(4, 3, (-self.far * self.near) / (self.far - self.near))
    self.proj:set(3, 4, 1.0)
    self.proj:set(4, 4, 0.0)
end

function Math3D.Camera:new(o, x, y, z, near, far, fov, width, height)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.pos = Math3D.Vec3D:new(nil, x or 0, y or 0, z or 0)
    o.near = near or 0.1
    o.far = far or 1000.0
    o.fov = fov or 90.0
    o.fov_rad = math.rad(self.fov)
    o.width = width or 800
    o.height = height or 600
    o.proj = Math3D.Matrix:new()
    o.aspect_ratio = self.height / self.width
    o:recalcProjMat()
    return o
end

Math3D.DirectionLight = {
    direction = Math3D.Vec3D:new(),
    directionNorm = Math3D.Vec3D:new()
}

function Math3D.DirectionLight:calcNorm()
    self.directionNorm.x = self.direction.x
    self.directionNorm.y = self.direction.y
    self.directionNorm.z = self.direction.z
    self.directionNorm:norm()
end

function Math3D.DirectionLight:new(o, x, y, z)
    o = o or {
        direction = Math3D.Vec3D:new(),
        directionNorm = Math3D.Vec3D:new()
    }
    setmetatable(o, self)
    self.__index = self
    o.direction.x = x or 0
    o.direction.y = y or 0
    o.direction.z = z or 0
    return o
end


return Math3D
