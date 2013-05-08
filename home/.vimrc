set nocompatible
"set gfn=Monospace\ 12 

let mapleader=","

"Seccion para manejar plugins
filetype off "Dice en la documentacion de Vundle que es requerido
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
 " let Vundle manage Vundle
 " required! 

Bundle 'gmarik/vundle'

Bundle 'EasyAccents'
Bundle 'Lokaltog/vim-easymotion'
Bundle 'SuperTab-continued.'
Bundle 'The-NERD-Commenter'
Bundle 'The-NERD-tree'
Bundle 'mru.vim'
Bundle 'surround.vim'
Bundle 'vimwiki'

filetype plugin indent on     " Es requerido en la documentacion de Vundle. 
"Fin seccion para manejar plugins

" Para vimwiki usar \tt para los elementos todo
map <leader>tt <Plug>VimwikiToggleListItem

let g:vimwiki_list =
	\ [{'path': '$HOME/Documentos/Wiki', 'path_html': '$HOME/html/wiki'}]
