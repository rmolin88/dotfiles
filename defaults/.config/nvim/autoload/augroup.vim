" File:					augroup.vim
" Description:	All autogroup should be group here. Unless it makes more sense
"								with some plugin
" Author:				Reinaldo Molina <rmolin88@gmail.com>
" Version:				0.0.0
" Last Modified: Aug 24 2017 16:25
" Created: Aug 24 2017 16:25

function! augroup#Set() abort
	" ALL_AUTOGROUP_STUFF
	" All of these options contain performance drawbacks but the most important
	" is foldmethod=syntax
	augroup Filetypes
		autocmd!
		autocmd Filetype fugitive nnoremap <buffer> <s-j> :b#<cr>

		autocmd Filetype wings_syntax set suffixesadd=.scp
		autocmd Filetype qf setlocal colorcolumn=""
		" Nerdtree Fix
		autocmd FileType nerdtree setlocal relativenumber
		" Set omnifunc for all others 									" not showing
		" autocmd FileType cs compiler msbuild

		" Display help vertical window not split
		autocmd FileType help wincmd L
		autocmd FileType help nnoremap <buffer> q :helpc<cr>
		autocmd FileType help setlocal relativenumber
		autocmd FileType help nnoremap <buffer> g0 g0

		autocmd FileType markdown,mkd setlocal conceallevel=0 wrap spell
					\ foldenable complete+=kspell ts=2 sw=2 sts=2
					\ comments+=b:-,b:* spelllang=en_us tw=0

		if exists('g:loaded_plugins')
			autocmd FileType markdown,mkd call pencil#init()
			autocmd FileType text         call pencil#init()
			autocmd FileType tex         call pencil#init()
		endif

		" formatoptions do not autowrap text
		autocmd FileType tex setlocal conceallevel=0 nowrap spell
					\ foldenable complete+=kspell ts=2 sw=2 sts=2
					\ spelllang=en_us tw=0 formatoptions-=tc colorcolumn=+1

		autocmd FileType mail setlocal spell spelllang=en,es wrap
					\ textwidth=72

		autocmd FileType vim setlocal tabstop=2 shiftwidth=2 softtabstop=2 nospell

		if has('unix')
			autocmd FileType c,cpp setlocal nowrap ts=2 sw=2 sts=2
		else
			autocmd FileType c,cpp setlocal nowrap ts=4 sw=4 sts=4
		endif
		autocmd FileType c,cpp setlocal nowrap fen
					\ fdn=88 define=^\\(#\\s*define\\|[a-z]*\\s*const\\s*[a-z]*\\)

		" Python
		" autocmd FileType python setlocal foldmethod=syntax

		autocmd FileType fzf inoremap <buffer> <c-j> <down>
		autocmd FileType fzf inoremap <buffer> <c-n> <down>

		autocmd FileType gitcommit setlocal spell spelllang=en

		autocmd FileType terminal setlocal nonumber norelativenumber bufhidden=hide
		autocmd FileType json syntax match Comment +\/\/.\+$+
	augroup END

	augroup CmdWin
		autocmd!
		autocmd CmdWinEnter * nnoremap <buffer> q i" <cr>
		autocmd CmdWinEnter * nnoremap <buffer> <cr> i<cr>
	augroup END

	" To improve syntax highlight speed. If something breaks with highlight
	" increase these number below
	" augroup vimrc
	" autocmd!
	" autocmd BufWinEnter,Syntax * syn sync minlines=80 maxlines=80
	" augroup END

	if exists('g:loaded_plugins')
		augroup VimType
			autocmd!
			" Sessions
			" Note: Fri Mar 03 2017 14:13 - This never works.
			" autocmd VimEnter * call utils#LoadSession('default.vim')
			" Thu Oct 05 2017 22:22: Special settings that are only detected after vim 
			" is loaded
			autocmd VimEnter * nested call s:on_vim_enter()
			autocmd VimLeave,BufEnter * call mappings#SaveSession(has('nvim') ?
				\ 'default_nvim.vim' : 'default_vim.vim')
			" Keep splits normalize
			autocmd VimResized * call s:normalize_window_size()
		augroup END

		augroup BuffTypes
			autocmd!
			autocmd BufRead,BufNewFile * call s:determine_buf_type()

			autocmd BufReadPost *
				\ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit' |
				\   exe "normal! g`\"" |
				\ endif

			autocmd BufWinEnter * call ctags#LoadCscopeDatabse()
			autocmd BufWinEnter * call status_line#SetVerControl()
		augroup END

		augroup FluxLike
			autocmd!
			autocmd VimEnter,BufEnter * call flux#Flux()
		augroup END
	endif

	" Depends on autoread being set
	augroup AutoRead
		autocmd!
		autocmd CursorHold * silent! checktime
	augroup END

	if has('nvim')
		augroup Terminal
			autocmd!
			autocmd TermOpen * set filetype=terminal
		augroup END
	else
		augroup Terminal
			autocmd!
			autocmd TerminalOpen *
						\ if &buftype == 'terminal' |
						\ setlocal bufhidden=hide |
						\ endif
		augroup END
	endif
endfunction

" Things to do after everything has being loaded
function! s:on_vim_enter() abort
	" This function needs to be here since most of the variables it checks are not
	" populated until vim init is done
	call options#SetCli()
	call plugin#AfterConfig()
	" if (argc() == 0) " If no arguments are passed load default session
		" call mappings#LoadSession(has('nvim') ?
					" \ 'default_nvim.vim' : 'default_vim.vim')
	" endif
endfunction

function! s:determine_buf_type() abort
	let l:ext = expand('%:e')
	if &verbose > 0
		echomsg 'Detecting buf type: ' l:ext
	endif
	if l:ext ==? 'ino' || l:ext ==? 'pde'
		set filetype=arduino
	elseif l:ext ==? 'scp'
		set filetype=wings_syntax
		" elseif ext ==? 'log'
		" setfiletype unreal-log
	elseif l:ext ==? 'set' || l:ext ==? 'sum'
		set filetype=dosini
	elseif l:ext ==? 'bin' || l:ext ==? 'pdf' || l:ext ==? 'hsr'
		if &verbose > 0
			echomsg 'Binary file detected'
		endif
		call s:set_bin_file_type()
	endif

endfunction

function! s:set_bin_file_type() abort
	let &l:bin=1
	%!xxd
	setlocal ft=xxd
	%!xxd -r
	setlocal nomodified
endfunction

function! s:normalize_window_size() abort
	execute "normal \<c-w>="
endfunction

" Thu Apr 26 2018 18:08: Never have being able to get this to work 
function! s:restore_last_file() abort
	while !v:vim_did_enter
		execute ':sleep 1m'
	endwhile

	execute "normal \<c-o>\<c-o>"
endfunction

function! s:update_root_dir() abort
	if !exists('*FindRootDirectory')
		return -1
	endif

	let g:root_dir = FindRootDirectory()
endfunction
