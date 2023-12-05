-- query.lua

-- DSICLAIMER
-- query.frustum() prints correctly for the (d, u, r) and (x, y ,z) co-ords but not for the frustum planes
-- qury.visible() does not work correctly 

local lsd = require "lsd"
local query = {}



-- HELPER FUNCTIONS


-- Function to cross multiply vectors
local function cross(v1, v2)
  return {
      v1[2]*v2[3] - v1[3]*v2[2],
      v1[3]*v2[1] - v1[1]*v2[3],
      v1[1]*v2[2] - v1[2]*v2[1]
  }
end

  -- Function to normalise vectors
  local function normalize(v)
    local mag = math.sqrt(v[1]^2 + v[2]^2 + v[3]^2)
    return { v[1]/mag, v[2]/mag, v[3]/mag }
end

-- Function to subtract vectors
local function subtract(v1, v2)
    return { v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3] }
end

local function add(v1, v2)
  return { v1[1] + v2[1], v1[2] + v2[2], v1[3] + v2[3] }
end

local function scalarMultiply(v, scalar)
  return { v[1] * scalar, v[2] * scalar, v[3] * scalar }
end

local function formatVector(v)
  return string.format("(%0.3f,%0.3f,%0.3f)", v[1], v[2], v[3])
end

local function dotProduct(v1, v2)
  return v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3]
end

-- Function to check if a point is within the frustum
local function isPointInFrustum(point, frustumPlanes)
  for _, plane in ipairs(frustumPlanes) do
    local distance = plane.normal[1] * point[1] +
                     plane.normal[2] * point[2] +
                     plane.normal[3] * point[3] +
                     plane.distance
    if distance < 0 then
      return false
    end
  end
  return true
end

-- Function to check if any of a list of points is within the frustum
local function isAnyPointInFrustum(points, frustumPlanes)
  for _, point in ipairs(points) do
    if isPointInFrustum(point, frustumPlanes) then
      return true
    end
  end
  return false
end



-- ACTUAL FUNCTIONS


-- query.whatObjects()
function query.whatObjects()
	print(sf("%d known objects:", #sceneT))
	for _, object in ipairs(sceneT) do
	  print(sf("Name: %s; type %s", object.name, object.type))
	end
end


-- query.cameraParams()
function query.cameraParams()

  local function formatVector(vector)
      local formattedVector = {}
      for _, component in ipairs(vector) do
          table.insert(formattedVector, sf("%0.3f", component))
      end
      return "(" .. table.concat(formattedVector, ",") .. ")"
  end

  print("Camera location: " .. formatVector(cameraT.loc))
  print("Camera looking at: " .. formatVector(cameraT.lookat))
  print("Camera up direction (approx.): " .. formatVector(cameraT.upis))
  print("Camera dist to frontplane: " .. sf("%0.3f", cameraT.dfrontplane))
  print("Camera dist to backplane: " .. sf("%0.3f", cameraT.dbackplane))
  print("Camera frontplane halfangle: " .. sf("%0.3f", cameraT.halfangle))
  print("                  ratio: " .. sf("%0.3f", cameraT.rho))
end


-- query.directions()
function query.directions()

  -- Calculate direction vectors 
  -- Variables needed for query.directions() & query.frustum()
  forward = normalize(subtract(cameraT.lookat, cameraT.loc))  -- D
  right = normalize(cross(forward, cameraT.upis))  -- R
  up = cross(right, forward)  -- U

  -- Format and print the direction vectors
  print(sf("Directions: D=%s", formatVector(forward)))
  print(sf("            U=%s", formatVector(up)))
  print(sf("            R=%s", formatVector(right)))
end


-- query.frustum()
function query.frustum()

  local tanHalfAngle = math.tan(math.rad(cameraT.halfangle))
  local nearHeight = 2 * tanHalfAngle * cameraT.dfrontplane
  local nearWidth = nearHeight * cameraT.rho
  local farHeight = 2 * tanHalfAngle * cameraT.dbackplane
  local farWidth = farHeight * cameraT.rho

  local nearCenter = add(cameraT.loc, scalarMultiply(forward, cameraT.dfrontplane))
  local farCenter = add(cameraT.loc, scalarMultiply(forward, cameraT.dbackplane))

  local nearBottomLeft = subtract(subtract(nearCenter, scalarMultiply(up, nearHeight / 2)), scalarMultiply(right, nearWidth / 2))
  local nearBottomRight = add(subtract(nearCenter, scalarMultiply(up, nearHeight / 2)), scalarMultiply(right, nearWidth / 2))
  local nearTopLeft = subtract(add(nearCenter, scalarMultiply(up, nearHeight / 2)), scalarMultiply(right, nearWidth / 2))
  local nearTopRight = add(add(nearCenter, scalarMultiply(up, nearHeight / 2)), scalarMultiply(right, nearWidth / 2))

  local farBottomLeft = subtract(subtract(farCenter, scalarMultiply(up, farHeight / 2)), scalarMultiply(right, farWidth / 2))
  local farBottomRight = add(subtract(farCenter, scalarMultiply(up, farHeight / 2)), scalarMultiply(right, farWidth / 2))
  local farTopLeft = subtract(add(farCenter, scalarMultiply(up, farHeight / 2)), scalarMultiply(right, farWidth / 2))
  local farTopRight = add(add(farCenter, scalarMultiply(up, farHeight / 2)), scalarMultiply(right, farWidth / 2))

  local function calculateDurCoords(v)
    return {
      dotProduct(subtract(v, cameraT.loc), forward),
      dotProduct(subtract(v, cameraT.loc), up),
      dotProduct(subtract(v, cameraT.loc), right)
    }
  end

    -- Print the (d, u, r) coordinates of the frustum corners
  -- (d, u, r) coordinates, which are the vectors towards the direction, up, and right
  print("In (d,u,r) co-ords v_bl= " .. formatVector(calculateDurCoords(nearBottomLeft)))
  print("                   v_tl= " .. formatVector(calculateDurCoords(nearTopLeft)))
  print("                   v_br= " .. formatVector(calculateDurCoords(nearBottomRight)))
  print("                   v_tr= " .. formatVector(calculateDurCoords(nearTopRight)))
  print("                   w_bl= " .. formatVector(calculateDurCoords(farBottomLeft)))
  print("                   w_tl= " .. formatVector(calculateDurCoords(farTopLeft)))
  print("                   w_br= " .. formatVector(calculateDurCoords(farBottomRight)))
  print("                   w_tr= " .. formatVector(calculateDurCoords(farTopRight)))

  -- Print the (x, y, z) coordinates of the frustum corners
  -- (x, y, z) coordinates, which are the actual points in the 3D space of the frustum corners
  print("In (x,y,z) co-ords v_bl= " .. formatVector(nearBottomLeft))
  print("                   v_tl= " .. formatVector(nearTopLeft))
  print("                   v_br= " .. formatVector(nearBottomRight))
  print("                   v_tr= " .. formatVector(nearTopRight))
  print("                   w_bl= " .. formatVector(farBottomLeft))
  print("                   w_tl= " .. formatVector(farTopLeft))
  print("                   w_br= " .. formatVector(farBottomRight))
  print("                   w_tr= " .. formatVector(farTopRight))

-- Assuming forward, right, and up are already calculated and normalized correctly
local normals = {
  front = forward,
  back = scalarMultiply(forward, -1),
  top = normalize(cross(right, subtract(nearTopLeft, nearCenter))),
  bottom = normalize(cross(subtract(nearBottomRight, nearCenter), right)),
  left = normalize(cross(subtract(nearBottomLeft, nearCenter), up)),
  right = normalize(cross(up, subtract(nearTopRight, nearCenter)))
}

-- Points on the planes are simply one of the corners of near or far plane
local points = {
  front = nearBottomLeft,
  back = farBottomLeft,
  top = nearTopLeft,
  bottom = nearBottomRight,
  left = nearBottomLeft,
  right = nearTopRight
}

  print("The frustrum planes: front: " .. "n=" .. formatVector(normals.front) .. ";" .. " p=" .. formatVector(points.front))
  print("                      back: " .. "n=" .. formatVector(normals.back) .. ";" .. " p=" .. formatVector(points.back))
  print("                       top: " .. "n=" .. formatVector(normals.top) .. ";" .. " p=" .. formatVector(points.top))
  print("                    bottom: " .. "n=" .. formatVector(normals.bottom) .. ";" .. " p=" .. formatVector(points.bottom))
  print("                      left: " .. "n=" .. formatVector(normals.left) .. ";" .. " p=" .. formatVector(points.left))
  print("                     right: " .. "n=" .. formatVector(normals.right) .. ";" .. " p=" .. formatVector(points.right))

end


-- query.visible()
function query.visible(frustumPlanes)
  print("Visible objects:")
  for _, obj in ipairs(sceneT) do
    local isVisible = false
    local objectType = obj.type

    if objectType == "sphere" then
      isVisible = isPointInFrustum(obj.ctr, frustumPlanes)
    elseif objectType == "box" then
      local boxVertices = {
        obj.blf, -- bottom-left-front
        obj.trb, -- top-right-back
        -- Add other vertices based on blf and trb
      }
      isVisible = isAnyPointInFrustum(boxVertices, frustumPlanes)
    elseif objectType == "face" then
      isVisible = isAnyPointInFrustum(obj.verts, frustumPlanes)
    end

    if isVisible then
      print(sf("Object %s is fully visible", obj.name))
    else
      print(sf("Object %s is not visible", obj.name))
    end
  end
end

return query


