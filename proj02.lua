-- proj02.lua

local lsd = require "lsd"
local query = require "query"

local function main()
    lsd.read(arg[1]) -- read the lsd specification; this is mandatory

    print(query.whatObjects())
    print(query.cameraParams())
    print(query.directions())
    print(query.frustum())
    print(query.visible())
    os.exit()

--     -- Wait for user input to perform queries
--     while true do
--         io.write("Commands: whatObjects(), cameraParams(), directions(), frustum(), visible(), exit() \nEnter: ")
--         local input = io.read()  -- Reads a line from the user
--         print("\n")
--         if input == "whatObjects()" then
--             print(query.whatObjects())
--         elseif input == "cameraParams()" then
--             print(query.cameraParams())
--         elseif input == "directions()" then
--             print(query.directions())
--         elseif input == "frustum()" then
--             print(query.frustum())
--         elseif input == "visible()" then
--             print(query.visible())
--         elseif input == "exit()" then
--             os.exit()
--         else
--             print("Unknown command. Try again.")
--         end

--         print("\n")  -- Add an extra newline for readability
--     end
-- end

end main()

