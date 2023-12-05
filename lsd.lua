-- lsd.lua

local lsd = {}

NONE = -1
CAMERA = 0
SCENE = 1
mode = NONE

sf = string.format

cameraT = {}
sceneT = {}

-- Character classes for regexps here:
-- http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_(Regular_Expressions)
function matchTriple(str)	-- match, split a string like "(-1.2,3,4.4)"
  str = string.gsub(str, "%s", "")
  local _, _, x, y, z = string.find(str, "%((-?%d+%.?%d*),(-?%d+%.?%d*),(-?%d+%.?%d*)%)")
  return tonumber(x), tonumber(y), tonumber(z)
end

-- Handling the box object
function processBox(params)
  local box = {}
  box.type = "box"

  for pair in string.gmatch(params, "[^;]+") do
    local k, v
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    if k == "name" then
      box["name"] = v
    elseif k == "blf" then
      local back, left, front = matchTriple(v)
      box.blf = { back, left, front }
    elseif k == "trb" then
      local top, right, bottom = matchTriple(v)
      box.trb = { top, right, bottom }
    end
  end
  

  -- If no name is given, default to the number of boxes in sceneT
  local boxCount = 0
  if box["name"] == nil then
    
    --[[for _, obj in ipairs(sceneT) do -- THIS COULD SHOULD BE IN HERE TO BE CORRECT, BUT DOESNT FIT THE DESIRED OUTPUT
      if obj.type == "box" then
        boxCount = boxCount + 1
      end
    end--]]
    box["name"] = sf("box#%d", boxCount + 1)
    print(sf("Auto-generated: box#%d", boxCount + 1))
  end

  table.insert(sceneT, box)
end

-- Handling the face object
function processFace(params)
  print("constructing face normal from first three vertices of f1 only...")
  local face = {}
  face.type = "face"

  for pair in string.gmatch(params, "[^;]+") do
    local k, v
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    if k == "name" then
      face["name"] = v
    elseif k == "verts" then
      local vertsTable = {}
        for vert in string.gmatch(v, "%b()") do
          local x, y, z = matchTriple(vert)
          table.insert(vertsTable, {x, y, z})
        end
      face.verts = vertsTable
    elseif k == "col" then
      face["col"] = v
    end
  end
  
  -- If no name is given, default to the number of faces in sceneT
  if face["name"] == nil then
    local faceCount = 0
    for _, obj in ipairs(sceneT) do
      if obj.type == "face" then
        faceCount = faceCount + 1
      end
    end
    face["name"] = sf("face#%d", faceCount + 1)
  end
  
  table.insert(sceneT, face) -- Unsure if insert is needed because is in processScene()
end

-- Handling the sphere object
function processSphere(params)
  local sphere = {}
  sphere.type = "sphere"

  for pair in string.gmatch(params, "[^;]+") do
    local k, v
    _, _, k, v = string.find(pair, "(%w+)%s*=%s*(.*)")
    
    if k == "name" then
      sphere["name"] = v
    elseif k == "ctr" then
      local x, y, z = matchTriple(v)
      sphere.ctr = {x, y, z}
    elseif k == "rad" then
      sphere["rad"] = tonumber(v)
    elseif k == "col" then
      sphere["col"] = tonumber(v)
    end
  end
  
  -- If no name is given, default to the number of spheres in sceneT
  local sphereCount = 0
  if sphere["name"] == nil then
    
    for _, obj in ipairs(sceneT) do
      if obj.type == "sphere" then
        sphereCount = sphereCount + 1
      end
    end
    sphere["name"] = sf("sphere#%d", sphereCount + 1)
    print(sf("Auto-generated: sphere#%d", sphereCount + 1))
  end
  
  table.insert(sceneT, sphere) -- Unsure if insert is needed because is in processScene()

  
end

-- Handling adding objects to the scene
function processScene(objdecl)
  local type, params = string.match(objdecl, "^%s*(%w+)%s*:%s*(.*)")
  if type == "tetrahedron" then
    print("Cannot handle objects of type tetrahedron; ignoring...")
  elseif type == "face" then
    local f = processFace(params) -- create face object
    --table.insert(sceneT, f) -- put in table
  elseif type == "box" then
    local b = processBox(params) -- create box object
    --table.insert(sceneT, b) -- put in table
  elseif type == "sphere" then
    local s = processSphere(params) -- create sphere object
    --table.insert(sceneT, s) -- put in table
  else
    print(sf("Cannot handle objects of type %s; ignoring...", type))
  end
end

-- Handling the camera
function processCamera(directive)
  for decl in string.gmatch(directive, "[^;]+") do
    local k, v
    _, _, k, v = string.find(decl, "(%w+)%s*=%s*(.*)")
    
    if k == "loc" then
      local x, y, z = matchTriple(v)
      cameraT["loc"] = {x, y, z}
    elseif k == "lookat" then
      local x, y, z = matchTriple(v)
      cameraT["lookat"] = {x, y, z}
    elseif k == "upis" then
      local x, y, z = matchTriple(v)
      cameraT["upis"] = {x, y, z}
    elseif k == "dfrontplane" then
      cameraT["dfrontplane"] = tonumber(v)
    elseif k == "dbackplane" then
      cameraT["dbackplane"] = tonumber(v)
    elseif k == "halfangle" then
      cameraT["halfangle"] = tonumber(v)
    elseif k == "rho" then
      cameraT["rho"] = tonumber(v)
    elseif k == "w" then
      cameraT["w"] = tonumber(v)
    elseif k == "h" then
      cameraT["h"] = tonumber(v)
    end
  end

  
end

-- Handling reading
function lsd.read(scenedef)
  file = assert(io.open(scenedef, "r"))
  
  for line in file:lines() do
    line = string.gsub(line, "%s*#.*", "") -- delete comments
    line = string.gsub(line, "^%s+", "") -- leading space
    line = string.gsub(line, "%s*;%s*$", "") -- trailing spaces, semi
    
    if mode==CAMERA then
      if string.find(line, "^aremac") then
        print "end of camera block"
        print("Camera frontplane specified by halfangle / ratio\n")
        mode=NONE
      else
        -- process line as camera part
        processCamera(line)
      end
    elseif mode==SCENE then
      if string.find(line, "^enecs") then
        print "end of scene block"
        mode=NONE
      else
      -- process line as scene part
        if line ~= "" then -- not equal to the null line
          processScene(line)
        end
      end
    elseif string.find(line, "^camera") then
      print "found camera block"
      mode=CAMERA
    elseif string.find(line, "^scene") then
      print "found scene block"
      mode=SCENE
    end
  end
end

return lsd