-- OSGEO-Inject Neovim Project Configuration

-- Set project-specific options
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Format on save for JS/CSS
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.js", "*.css", "*.json" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Custom commands
vim.api.nvim_create_user_command("OsgeoServe", function()
  vim.cmd("terminal npm run serve")
end, { desc = "Start OSGEO-Inject test server" })

vim.api.nvim_create_user_command("OsgeoBuild", function()
  vim.cmd("!npm run build")
end, { desc = "Build OSGEO-Inject assets" })

vim.api.nvim_create_user_command("OsgeoLint", function()
  vim.cmd("!npm run lint")
end, { desc = "Lint OSGEO-Inject code" })

vim.api.nvim_create_user_command("OsgeoDocs", function()
  vim.cmd("terminal npm run docs:serve")
end, { desc = "Serve OSGEO-Inject documentation" })

vim.api.nvim_create_user_command("OsgeoOnboard", function()
  vim.cmd("terminal ./scripts/onboard-site.sh")
end, { desc = "Run site onboarding script" })

vim.api.nvim_create_user_command("OsgeoAnnounce", function()
  vim.cmd("terminal ./scripts/update-announcement.sh")
end, { desc = "Update announcement" })

-- LSP configuration for this project
local lspconfig = require("lspconfig")

-- JavaScript/TypeScript
if lspconfig.tsserver then
  lspconfig.tsserver.setup({
    root_dir = function()
      return vim.fn.getcwd()
    end,
  })
end

-- CSS
if lspconfig.cssls then
  lspconfig.cssls.setup({
    root_dir = function()
      return vim.fn.getcwd()
    end,
  })
end

-- Nix
if lspconfig.nil_ls then
  lspconfig.nil_ls.setup({
    root_dir = function()
      return vim.fn.getcwd()
    end,
  })
end

-- Diagnostics configuration
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
})

print("OSGEO-Inject project loaded")
