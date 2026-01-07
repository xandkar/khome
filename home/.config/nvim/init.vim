"==============================================================================
" Plugins
"==============================================================================

" Alternative plugin managers to try:
" - https://github.com/Shougo/dein.vim

" BEGIN Vim-Plug (https://github.com/junegunn/vim-plug)
" Run :PlugInstall after adding a new plugin
call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'prisma/vim-prisma'  " Syntax for Prisma. The ORM thing used in Nosh repo.
Plug 'z0mbix/vim-shfmt', { 'for': 'sh' }
Plug 'dense-analysis/ale' " Syntastic's spiritual succesor
Plug 'preservim/nerdtree'
"Plug 'nvim-tree/nvim-web-devicons' " Needs patched fonts: https://www.nerdfonts.com/
" Plug 'phha/zenburn.nvim'
Plug 'hexbloom/zenburn.nvim', {'branch': 'semantic-highlight-support'}
" Plug 'zenbones-theme/zenbones.nvim'
Plug 'itchyny/lightline.vim'
Plug 'numToStr/Comment.nvim'
Plug 'rust-lang/rust.vim'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'neoclide/coc.nvim', {'commit': '1baa8dcb09ee427573aba665807e3f757659f98b'}
Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'npm ci'}
" Plug 'neovim/nvim-lspconfig'

" BEGIN codecompanion
" https://codecompanion.olimorris.dev/installation.html
Plug 'nvim-lua/plenary.nvim', {'branch': 'master'}
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'olimorris/codecompanion.nvim'
" END codecompanion

" Plug 'hrsh7th/cmp-nvim-lsp', {'branch': 'main'}
" Plug 'hrsh7th/cmp-buffer', {'branch': 'main'}
" Plug 'hrsh7th/cmp-path', {'branch': 'main'}
" Plug 'hrsh7th/nvim-cmp', {'branch': 'main'}
"
" " Only because nvim-cmp _requires_ snippets
" Plug 'hrsh7th/cmp-vsnip', {'branch': 'main'}
" Plug 'hrsh7th/vim-vsnip'

" Plug 'simrat39/rust-tools.nvim'

"" Uses deprecated calls and has been archived by the maintainer:
"" https://github.com/simrat39/symbols-outline.nvim
"" Also not really better than CocOutline.
" Plug 'simrat39/symbols-outline.nvim'

" Typst stuff:
Plug 'kaarmu/typst.vim'
" https://typst.app/
" https://github.com/typst/typst
" https://github.com/typst/typst/issues/175
" https://github.com/kaarmu/typst.vim
" https://github.com/chomosuke/typst-preview.nvim
" https://github.com/SeniorMars/typst.nvim

call plug#end()
" END Vim-Plug

" lua require("symbols-outline").setup()
"" luafile ~/.config/nvim/setup-symbols-outline.lua

lua require('Comment').setup()
" luafile ~/.config/nvim/setup-rust-tools.lua
"luafile ~/.config/nvim/setup-lsp-rust-jonhoo.lua
source ~/.config/nvim/setup-coc.vim

" lua require('codecompanion').setup()
luafile ~/.config/nvim/setup-codecompanion.lua

" NERDTree
let NERDTreeShowLineNumbers=1

" rust.vim
let g:rustfmt_autosave = 1
"let g:rustfmt_options = '--edition 2021' " XXX Without specifying edition,
                                         " presence of async in file prevents
                                         " it from being formatted on save.

" shfmt
let g:shfmt_extra_args = '--indent 4 --language-dialect bash'
" let g:shfmt_fmt_on_save = 1 " on-save probably too invasive to mod existing scripts.

"==============================================================================
" Defaults
"==============================================================================

"------------------------------------------------------------------------------
" General
"------------------------------------------------------------------------------
set nocompatible            " Because plain vi is a bit annoying
set nu                      " Line numbers in gutter
"set rnu                     " Relative number. relativenumber rnu norelativenumber nornu
set ruler                   " Line and column numbers in status
set splitright splitbelow   " Split window order
set bs=2                    " Enable backspace key
set history=1000            " Bump history from default of 20
set modeline
set modelines=3
set ttimeoutlen=100         " Reduce delay when addinng libe above ("O")
"set fileformats=unix
filetype on
filetype plugin on
set mouse=a                 " To scroll Coc tooltips. https://github.com/neoclide/coc.nvim/issues/1405
set spellfile=~/.vim/spell/en.utf-8.add
set spelllang=en,ru,la
set nohidden                " No hidden buffers, please.

" lightline
set laststatus=2
set noshowmode
let g:lightline = {
    \ 'colorscheme': 'seoul256',
    \ 'component_function': {
    \   'filename': 'LightlineFilename'
    \ }
\}

function! LightlineFilename()
  let l:filename = expand('%:t')
  let l:parentdir = expand('%:h:t')
  return l:parentdir . '/' . l:filename
endfunction

"------------------------------------------------------------------------------
" Color
"------------------------------------------------------------------------------
set t_Co=256
syntax enable
set background=dark
colorscheme zenburn

au TextYankPost * lua vim.highlight.on_yank {higroup="IncSearch", timeout=250, on_visual=true, on_macro=true}

"hi Normal guibg=NONE    " Transparency
"hi Normal ctermbg=NONE  " Transparency

"------------------------------------------------------------------------------
" Search
"------------------------------------------------------------------------------
set hlsearch
set incsearch
set noignorecase
set smartcase

"------------------------------------------------------------------------------
" Text format / indentation
"------------------------------------------------------------------------------
filetype indent on
set autoindent
set smartindent
set expandtab
set tabstop=8
set softtabstop=4
set shiftwidth=4
set textwidth=0  " What is the point of this again? Prevent auto-wrapping?

"------------------------------------------------------------------------------
" Code folding
"------------------------------------------------------------------------------
set foldmethod=indent
set nofoldenable

"------------------------------------------------------------------------------
" Style enforcement
"------------------------------------------------------------------------------
" Lines too-long
let &colorcolumn=join(range(80,80),",")
"match  ErrorMsg '\%>79v.\+'

match  ErrorMsg '\s\+$'  " Trailing whitespace
"2match ErrorMsg '\t'     " Tabs

" TODO: How to match more than 2 things? 3match is reserved for brackets.

"==============================================================================
" Per FileType overrides
"==============================================================================

" C
autocmd FileType c set noexpandtab | set shiftwidth=8 | set softtabstop=8

" TypeScript
" TODO Why did I ever want to not expand tabs for TS?
" autocmd FileType typescript set noexpandtab | set shiftwidth=8 | set softtabstop=8

" R
autocmd FileType r set softtabstop=2 | set shiftwidth=2

" Python
autocmd FileType python set omnifunc=pythoncomplete#Complete

" Git commit
autocmd FileType gitcommit set spell

" Markdown
"autocmd FileType markdown set spell
autocmd FileType markdown set expandtab | set softtabstop=2 | set shiftwidth=2

" HTML
autocmd FileType html set spell

" MediaWiki
autocmd FileType mediawiki set spell
autocmd FileType mediawiki set set softtabstop=2 | set shiftwidth=2

" Tiger
autocmd BufNewFile,BufRead *.tig set filetype=tiger

" SML
autocmd BufNewFile,BufRead *.sig set filetype=sml

" Mathematica
autocmd BufNewFile,BufRead *.m  set filetype=mma
autocmd BufNewFile,BufRead *.mt set filetype=mma
autocmd FileType mma set softtabstop=2 | set shiftwidth=2

" F#
autocmd FileType fsharp set softtabstop=4 | set shiftwidth=4

" twtxt.txt
autocmd BufNewFile,BufRead twtxt.txt set filetype=conf | set noexpandtab

" Scheme
autocmd FileType scheme set softtabstop=2 | set shiftwidth=2

" Racket
autocmd FileType racket setlocal equalprg=scmindent.rkt
"autocmd FileType racket setlocal equalprg=raco\ fmt

" Erlang
"autocmd FileType erlang setlocal equalprg=erlfmt
autocmd FileType erlang set softtabstop=4 | set shiftwidth=4

" Django templates
autocmd FileType htmldjango set softtabstop=4 | set shiftwidth=4 | set expandtab

" -----------------------------------------------------------------------------
" TypeScript
" -----------------------------------------------------------------------------
"let g:tsuquyomi_completion_detail = 1
"let g:tsuquyomi_use_local_typescript = 0
"let g:syntastic_typescript_checkers = ['tsuquyomi']

" -----------------------------------------------------------------------------
" Racket
" -----------------------------------------------------------------------------
let g:syntastic_enable_racket_racket_checker = 0

" -----------------------------------------------------------------------------
" OCaml
" -----------------------------------------------------------------------------
autocmd FileType ocaml set softtabstop=2 | set shiftwidth=2
