" ============================================================================
" .vimrc - Clean, fast, and modern Vim configuration
" ============================================================================

" --- General Settings ---
set nocompatible              " Be iMproved, required for modern vim
syntax on                     " Enable syntax highlighting
filetype plugin indent on     " Enable filetype detection, plugins, and indentation

set encoding=utf-8
set fileencoding=utf-8
set number                    " Show line numbers
set relativenumber            " Relative line numbers for easier jumping
set ruler                     " Show cursor position in status line
set cursorline                " Highlight current line
set showcmd                   " Show incomplete commands in bottom bar
set showmatch                 " Highlight matching [{()}]
set laststatus=2              " Always show statusline
set backspace=indent,eol,start " Modern backspace behavior

" --- Indentation & Tabs ---
set tabstop=4                 " Number of visual spaces per TAB
set softtabstop=4             " Number of spaces in tab when editing
set shiftwidth=4              " Number of spaces for (auto)indent
set expandtab                 " Convert tabs to spaces
set autoindent
set smartindent

" --- Search Settings ---
set hlsearch                  " Highlight search matches
set incsearch                 " Incremental search (search as you type)
set ignorecase                " Case insensitive search...
set smartcase                 " ...unless uppercase character is entered

" --- Performance & Persistence ---
set lazyredraw                " Don't redraw while executing macros
set updatetime=300            " Faster completion and gitgutter updates
set nobackup                  " Don't create backup files
set nowritebackup
set noswapfile                " Disable swapfiles

" --- Key Mappings ---
let mapleader = " "           " Set Space as leader key

" Clear search highlights with <Leader>/
nnoremap <silent> <leader>/ :nohlsearch<CR>

" Fast split navigation with Ctrl + hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" --- fzf (Fuzzy Finder) Mappings ---
" Space + f : Fuzzy find files in project
nnoremap <silent> <leader>f :Files<CR>
" Space + b : Fuzzy find open buffers
nnoremap <silent> <leader>b :Buffers<CR>
" Space + g : Fuzzy find Git-tracked files
nnoremap <silent> <leader>g :GFiles<CR>
" Space + h : Fuzzy find file / command history
nnoremap <silent> <leader>h :History<CR>
" Space + l : Fuzzy find lines in current buffer
nnoremap <silent> <leader>l :BLines<CR>

" --- Vimwiki Configuration ---
" Configured to use Markdown syntax and store wikis in ~/vimwiki
let g:vimwiki_list = [{
    \ 'path': '~/vimwiki/',
    \ 'syntax': 'markdown',
    \ 'ext': '.md',
    \ 'auto_toc': 1,
    \ 'auto_tags': 1,
    \ 'auto_generate_tags': 1
\ }]
let g:vimwiki_global_ext = 0  " Only consider files inside ~/vimwiki as wiki files

" --- Statusline (Minimalist & Informative) ---
set statusline=
set statusline+=\ %f\ %m\ %r  " File path, modified, read-only
set statusline+=%=            " Right align separator
set statusline+=[%{&filetype}]\ %y\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\ %l/%L:%c\   " Line / Total lines : Column
