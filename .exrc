" OSGEO-Inject Neovim Configuration
" Leader key shortcuts under <leader>p

" Project-specific which-key mappings
lua << EOF
local wk = require("which-key")
wk.register({
  p = {
    name = "OSGEO-Inject",
    -- Build commands
    b = { "<cmd>!npm run build<cr>", "Build minified assets" },
    B = { "<cmd>!nix build<cr>", "Nix build" },

    -- Lint and format
    l = { "<cmd>!npm run lint<cr>", "Lint all" },
    f = { "<cmd>!npm run format<cr>", "Format all" },

    -- Serve
    s = { "<cmd>!npm run serve<cr>", "Serve test server" },
    S = { "<cmd>terminal npm run serve<cr>", "Serve in terminal" },

    -- Documentation
    d = { "<cmd>!npm run docs:serve<cr>", "Serve docs" },
    D = { "<cmd>!npm run docs:build<cr>", "Build docs" },

    -- Testing
    t = { "<cmd>!npm test<cr>", "Run tests" },

    -- Scripts
    o = { "<cmd>terminal ./scripts/onboard-site.sh<cr>", "Onboard site" },
    a = { "<cmd>terminal ./scripts/update-announcement.sh<cr>", "Update announcement" },
    k = { "<cmd>terminal ./scripts/backup.sh<cr>", "Backup" },
    r = { "<cmd>terminal ./scripts/restore.sh<cr>", "Restore" },

    -- Git
    g = {
      name = "Git",
      s = { "<cmd>Git status<cr>", "Status" },
      c = { "<cmd>Git commit<cr>", "Commit" },
      p = { "<cmd>Git push<cr>", "Push" },
    },

    -- Nix
    n = {
      name = "Nix",
      d = { "<cmd>!nix develop<cr>", "Enter dev shell" },
      c = { "<cmd>!nix flake check<cr>", "Check flake" },
      u = { "<cmd>!nix flake update<cr>", "Update flake" },
    },
  },
}, { prefix = "<leader>" })
EOF
