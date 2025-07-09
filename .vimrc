" Sync clipboard between Vim and host system
set clipboard=unnamed,unnamedplus

" Enable relative line numbers for easier navigation
set number relativenumber

" Enable persistent undo that syncs with VSCode
set undofile
set undodir=~/.vim/undodir

" Allow text selection in visual mode without immediate copying
xnoremap p pgvy

" Basic settings for better usability
set ignorecase      " Case insensitive search
set smartcase       " Case sensitive when search includes uppercase
set incsearch       " Show search matches as you type
set hlsearch        " Highlight search results

" Indent settings
set autoindent
set expandtab
set tabstop=2
set shiftwidth=2

" Allow backspace over everything in insert mode
set backspace=indent,eol,start
