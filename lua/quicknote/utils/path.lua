local path = require("plenary.path")
local config = require("quicknote.utils.config")
local sha = require("quicknote.utils.sha")

local M = {}

-- Get data path of where quicknote root folder will be stored
-- if mode is "residient" return $XGD_STATE_HOME/quicknote
-- if mode is "portable" return $PWD/.quicknote
M.GetDataPath = function()
  local mode = config.GetMode()
  if mode == "resident" then
    return vim.fs.normalize(vim.fn.stdpath("state") .. "/quicknote")
  elseif mode == "portable" then
    return vim.fs.normalize(vim.fn.getcwd() .. "/.quicknote")
  else
    error("Invalid mode: " .. mode .. ". Valid modes are: resident, portable")
  end
end

local getHashedNoteDirPath = function(filePath)
  -- data path is where note dir is stored
  local dataPath = M.GetDataPath()
  -- get hashed note dir name
  if config.GetMode() == "portable" then
    -- make the path relative to the current working directory
    filePath = path:new(filePath):make_relative()
  else -- for resident mode, notes can be separated by git branch
    filePath = path:new(filePath).filename
    local gitBranchRecognizable = config.IsGitBranchRecognizable()
    if gitBranchRecognizable == true then
      -- get the current git branch
      local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD")
      if vim.v.shell_error == 0 then
        if branch == "HEAD" then
          -- the HEAD is detached, use the commit id instead
          branch = vim.fn.system("git rev-parse HEAD")
        end
      else
        branch = ""
      end
      filePath = filePath .. branch -- append git branch to the
    end
  end
  local noteDirName = sha.sha1(filePath) -- hash current buffer path
  -- get hashed note dir path
  local noteDirPath = path:new(dataPath, noteDirName).filename
  return noteDirPath
end
M.getHashedNoteDirPath = getHashedNoteDirPath

-- Get the path to the notes directory corresponding to the current buffer
-- Note: one buffer can have multiple notes; the name of the dir is the hash of the buffer file name
local getNoteDirPathForCurrentBuffer = function()
  -- get current buffer file path
  local currentBufferPath = vim.api.nvim_buf_get_name(0)

  -- get note dir path
  local noteDirPath = getHashedNoteDirPath(currentBufferPath)

  return noteDirPath
end
M.getNoteDirPathForCurrentBuffer = getNoteDirPathForCurrentBuffer

-- same as getNoteDirPathForCurrentBuffer but for a CWD instead of the current buffer
local getNoteDirPathForCWD = function()
  -- get CWD path
  local cwdPath = vim.fn.getcwd()

  -- get note dir path
  local noteDirPath = getHashedNoteDirPath(cwdPath)

  return noteDirPath
end
M.getNoteDirPathForCWD = getNoteDirPathForCWD

-- same as getNoteDirPath*, but for a global note
local getNoteDirPathForGlobal = function()
  local dataPath = M.GetDataPath()
  local noteDirName = "global"
  local noteDirPath = path:new(dataPath, noteDirName).filename

  return noteDirPath
end
M.getNoteDirPathForGlobal = getNoteDirPathForGlobal

return M
