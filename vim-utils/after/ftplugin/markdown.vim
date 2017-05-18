" File:					markdown.vim
" Description:	After default ftplugin for markdown
" Author:				Reinaldo Molina <rmolin88@gmail.com>
" Version:			1.0.0
" Last Modified: Tue May 02 2017 10:18
" Created:					Wed Nov 30 2016 11:02

" Only do this when not done yet for this buffer
if exists("b:did_markdown_ftplugin")
	finish
endif

" Don't load another plugin for this buffer
let b:did_markdown_ftplugin = 1

setlocal foldenable
setlocal foldexpr=MarkdownLevel()
setlocal foldmethod=expr
setlocal spell spelllang=en_us

" TODO.RM-Fri Apr 28 2017 15:43: Fix these mappings  
if !exists("no_plugin_maps") && !exists("no_markdown_maps")
	" Encapsulate in markdown file from current line until end of file in ```
	nnoremap <buffer> <unique> <Leader>l` :normal i````cpp<Esc>Go```<Esc><CR>
	" Markdown fix _ showing red
	nnoremap <buffer> <Leader>lf :%s/_/\\_/gc<CR>
	nnoremap <buffer> <unique> <Leader>ld :call utils#TodoCreate()<CR>
	nnoremap <buffer> <unique> <Leader>lm :call utils#TodoMark()<CR>
	nnoremap <buffer> <unique> <Leader>lM :call utils#TodoClearMark()<CR>
	inoremap <buffer> * **<Left>

	if has('unix')
		" TODO.RM-Thu May 18 2017 12:17: This should be changed to opera  
		nnoremap <buffer> <unique> <Leader>lr :!google-chrome-stable %<CR>
	endif
endif

function! MarkdownLevel()
	if getline(v:lnum) =~ '^# .*$'
		return ">1"
	endif
	if getline(v:lnum) =~ '^## .*$'
		return ">2"
	endif
	if getline(v:lnum) =~ '^### .*$'
		return ">3"
	endif
	if getline(v:lnum) =~ '^#### .*$'
		return ">4"
	endif
	if getline(v:lnum) =~ '^##### .*$'
		return ">5"
	endif
	if getline(v:lnum) =~ '^###### .*$'
		return ">6"
	endif
	return "="
endfunction

let b:undo_ftplugin += "setl foldenable< foldexpr< foldmethod< spell< spelllang<" 
