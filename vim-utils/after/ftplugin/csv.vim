" File:					csv.vim
" Description:	After default ftplugin for csv files
" Author:				Reinaldo Molina <rmolin88@gmail.com>
" Version:				0.0.0
" Last Modified: Sep 29 2017 10:10
" Created: Sep 29 2017 10:10

" Only do this when not done yet for this buffer
if exists("b:did_csv_ftplugin")
	finish
endif

" Don't load another plugin for this buffer
let b:did_csv_ftplugin = 1

" If editing a csv file gets too slow remove this option
setlocal cursorline

" Fri Sep 29 2017 10:26: Cant include no_csv_maps because the csv.vim plugin took over that variable
if !exists("no_plugin_maps")
	nnoremap <buffer> <c-j> f,	
	nnoremap <buffer> <c-k> F,	
	nnoremap <buffer> <Leader>lf ggVG<bar>:ArrangeColumn!<cr>
endif

function! CsvArrangeColumns() abort
	if !exists(':ArrangeColumn')
		echomsg 'CsvArrangeColumns(): csv.vim plugin not available'
		return
	endif

	if getfsize(expand('%')) > 1048576
		echomsg 'File is too big'
		return
	endif

	let save_cursor = getcurpos()
	silent! undojoin
	%UnArrangeColumn
	%ArrangeColumn!
	call setpos('.', save_cursor)
endfunction

let b:undo_ftplugin = "setlocal cursorline<" 
