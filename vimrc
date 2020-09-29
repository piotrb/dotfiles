set nocompatible      " We're running Vim, not Vi!

source ~/.vim/bundle.vim

color distinguished

set modeline

let g:Guifont="Menlo Regular for Powerline:h13"

""""""""""""""""""""""""""""" Cusror Line

se nocursorline
se nocursorcolumn

"autocmd WinEnter * setlocal cursorline
"autocmd WinLeave * setlocal nocursorline

"autocmd WinEnter * setlocal cursorcolumn
"autocmd WinLeave * setlocal nocursorcolumn

"se cursorline
"se cursorcolumn
"hi CursorLine   ctermbg=233 guibg=#202020
"hi CursorColumn ctermbg=233 guibg=#202020

hi Cursor       guibg=#999999 guifg=#000000
hi SpecialKey   guifg=gray guibg=#660000

""""""""""""""""""""""""""""" Status Line

hi StatusLine cterm=NONE ctermbg=darkgreen ctermfg=black gui=bold guibg=green guifg=black
hi StatusLineNC cterm=NONE ctermbg=black ctermfg=lightgray gui=bold guibg=black guifg=lightgray

""""""""""""""""""""""""""""" Extra Whitespace

highlight ExtraWhitespace ctermbg=red guibg=red ctermfg=gray guifg=gray
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

""""""""""""""""""""""""""""" Clipboard

" sets the clipboard to the system clipboard
"set clipboard=unnamed

""""""""""""""""""""""""""""" Folding

"set re=2
"let g:ruby_fold=1
"set foldmethod=syntax
"set foldlevelstart=20
"set foldnestmax=5

"Sourced from vim tip: http://vim.wikia.com/wiki/Keep_folds_closed_while_inserting_text
autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif

""""""""""""""""""""""""""""" Views

"autocmd BufWinLeave *.* mkview
"autocmd BufWinEnter *.* silent loadview

""""""""""""""""""""""""""""" Syntax

au BufNewFile,BufRead *.god set filetype=ruby
au BufNewFile,BufRead *.rxls set filetype=ruby
au BufNewFile,BufRead *.es6 set filetype=javascript

filetype on           " Enable filetype detection
filetype indent on    " Enable filetype-specific indenting
filetype plugin on    " Enable filetype-specific plugins
syntax on             " Enable syntax highlighting

au FileType ruby setlocal shiftwidth=2 softtabstop=2 tabstop=2 expandtab autoindent
au FileType shell setlocal shiftwidth=2 softtabstop=2 tabstop=2 expandtab autoindent

au FileType gitcommit set tw=0

set listchars=tab:▸\ ,eol:¬
set list!
nmap <leader>l :set list!<CR>

if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

""""""""""""""""""""""""""""" Powerline

"set statusline=%f\ %m\ %r

"python from powerline.vim import setup as powerline_setup
"python powerline_setup()
"python del powerline_setup

""""""""""""""""""""""""""""" Airline

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

""""""""""""""""""""""""""""" Maps

nmap <Leader>N :NERDTreeFind<CR>
map <Leader>n :NERDTreeToggle<CR>

map <Leader>ms :MSExecCmd<space>

nmap <Leader>= :tabnew<cr>
nmap <Leader>- :tabclose<cr>
nmap <Leader>, :tabprevious<cr>
nmap <Leader>. :tabnext<cr>

" quick pane switching
map <c-h> <C-w>h
map <c-j> <C-w>j
map <c-k> <C-w>k
map <c-l> <C-w>l

map <Leader>wq <C-w>q

map <Leader>w<Left> <C-w>h
map <Leader>w<Down> <C-w>j
map <Leader>w<Up> <C-w>k
map <Leader>w<Right> <C-w>l

map <Leader>W<Left>  <C-w>H
map <Leader>W<Down>  <C-w>J
map <Leader>W<Up>    <C-w>K
map <Leader>W<Right> <C-w>L

""""""""""""""""""""""""""""" Customizations

let g:NERDTreeQuitOnOpen  = 1
let g:syntastic_ruby_rubocop_exec = 'rubocop.sh'
let g:syntastic_ruby_checkers = ['ruby', 'rubocop']
set colorcolumn=120

" RSpec.vim mappings
map <Leader>T :call RunCurrentSpecFile()<CR>
map <Leader>S :call RunNearestSpec()<CR>
map <Leader>L :call RunLastSpec()<CR>
map <Leader>A :call RunAllSpecs()<CR>

let g:rspec_command = "Dispatch spring rspec -f p -b {spec}"

let g:ctrlp_user_command = {
	\ 'types': {
		\ 1: ['.git', 'cd %s && git ls-files'],
		\ 2: ['.hg', 'hg --cwd %s locate -I .'],
		\ },
	\ 'fallback': 'find %s -type f'
	\ }

autocmd BufNewFile,BufRead *.slim setlocal filetype=slim

""""""""""""""""""""""""""""" Options

set hlsearch      " highlight search terms
set incsearch     " show search matches as you type

set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep

set nobackup
set noswapfile

set tags+=gems.tags

" Skip Vim Intro
set shortmess+=I
