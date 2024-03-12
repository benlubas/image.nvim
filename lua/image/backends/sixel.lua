local utils = require("image.utils")

---@type Backend
---@diagnostic disable-next-line: missing-fields
local backend = {
  ---@diagnostic disable-next-line: assign-type-mismatch
  state = nil,
  features = {
    crop = true,
  },
}

backend.setup = function(state)
  backend.state = state

  if utils.tmux.is_tmux and not utils.tmux.has_passthrough then
    utils.throw("tmux does not have allow-passthrough enabled")
    return
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      backend.clear()
    end,
  })
end

local echoraw = function(str)
  vim.fn.chansend(vim.v.stderr, str)
end

local send_sequence = function(path, lnum, cnum, width_px, height_px)
  -- save cursor pos
  echoraw("\27[s")
  -- move cursor pos
  echoraw(string.format("\27[%d;%dH", lnum, cnum))
  -- display sixels
  -- TODO: img2sixel supports cropping, should refactor kittys cropping code so it can be used here
  echoraw(vim.fn.system(string.format("img2sixel %s -w %d -h %d", path, width_px, height_px)))
  -- restore cursor pos
  echoraw("\27[u")
end

backend.render = function(image, x, y, width, height)
  send_sequence(image.cropped_path, x, y, width, height)

  image.is_rendered = true
  backend.state.images[image.id] = image
end

backend.clear = function(image_id, shallow)
  -- one
  if image_id then
    local image = backend.state.images[image_id]
    if not image then return end

    -- TODO: How TF do I clear the image?

    image.is_rendered = false
    if not shallow then backend.state.images[image_id] = nil end
    return
  end

  -- all
  for id, image in pairs(backend.state.images) do
    -- TODO: same ^
    image.is_rendered = false
    if not shallow then backend.state.images[id] = nil end
  end
end

return backend
