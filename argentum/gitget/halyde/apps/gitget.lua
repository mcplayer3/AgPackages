local component = import("component")
local fs = import("filesystem")
local json = import("json")
local serialize = import("serialize")
if not component.list("internet") then
    print("\x1b[91mThis program requires an internet card to run.")
end

print("Enter the repository name (ex. Your-Name/Your-Repo): ")
local repo = read()
print("Enter the branch name (ex. main): ")
local branch = read()

print("Enter a directory or disk short UUID to copy files to \x1b[93m(prefix dirs in the current directory with \"./\"!)\x1b[0m: ")
local outputdir = read()
local uuidchars = "0123456789abcdef"
if string.find(uuidchars, string.sub(outputdir, 1, 1), 1, true) then
    outputdir = "/mnt/" .. outputdir
elseif string.sub(outputdir, 1, 1) ~= "/" then
    outputdir = shell.getWorkingDirectory() .. outputdir
end
if not fs.isDirectory(outputdir) then
    print("\x1b[91mThe specified path \"" .. outputdir .. "\" is not a directory.")
    return
end
if not fs.exists(outputdir) then
    fs.makeDirectory(outputdir)
end
if string.sub(outputdir, -1, -1) ~= "/" then
    outputdir = outputdir .. "/"
end
repeat
    print("The output directory is " .. outputdir .. ". Continue? [Y/N]")
    local choice = string.upper(read())
    if choice == "N" then
        return
    end
until choice == "Y"

local function download(url, output) -- adapted from download.lua
    if not url or not output then
        return false, "Missing argument(s)."
    end
    if fs.isDirectory(output) then
        return false, "The specified location is a directory."
    end
    local internet = component.internet
    local request, data, tmpdata = nil, "", nil
    local status, errorMessage = pcall(function()
        request = internet.request(url)
        request:finishConnect()
    end)
    if not status then
        return false, errorMessage
    end
    local responseCode = request:response()
    if responseCode and responseCode ~= 200 then
        return false, tostring(responseCode)
    end
    repeat
        tmpdata = request.read(math.huge)
        data = data .. (tmpdata or "")
    until not tmpdata
    local handle = fs.open(output, "w")
    handle:write(data)
    handle:close()
    return true, nil
end

if not fs.exists("/tmp/mmaker/") then
    fs.makeDirectory("/tmp/mmaker/")
end

fs.makeDirectory(outputdir .. ".git")
local success, err = download("https://api.github.com/repos/" .. repo .."/git/trees/" .. branch .. "?recursive=1", outputdir .. ".git/index.json")
if not success then
    print("\x1b[91mDownload on URL " .. "https://api.github.com/repos/" .. repo .."/git/trees/" .. branch .. "?recursive=1" .. " failed: " .. err)
    print("\x1b[91mDownload cannot continue.")
    return
end

local handle = fs.open(outputdir .. ".git/index.json")
local tmpdata = ""
local data = ""
repeat
    tmpdata = handle:read(math.huge or math.maxinteger)
    data = data .. (tmpdata or "")
until not tmpdata
handle:close()
local index = json.decode(data)

handle = fs.open(outputdir .. "index.txt", "w")
handle:write(serialize.table(index))
handle:close()

for i in ipairs(index.tree) do
    local path = index.tree[i].path
    local url = "https://raw.githubusercontent.com/" .. repo .. "/refs/heads/" .. branch .. "/" .. path
    local type = index.tree[i].type
    if type == "tree" then
        fs.makeDirectory(outputdir .. path)
    elseif type == "blob" then
        success, err = download(url, outputdir .. path)
        if not success then
            print("\x1b[91mDownload on URL " .. url .. " at path " .. outputdir .. path .. " failed: " .. err)
            break
        end
        print("Saved file " .. outputdir .. path)
    end
end

print("\x1b[92mFinished downloading " .. repo .. "/" .. branch )