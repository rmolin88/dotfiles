" File:					c.vim
" Description:	After default ftplugin for c
" Author:				Reinaldo Molina <rmolin88@gmail.com>
" Version:			1.0.0
" Last Modified: Sat Jun 03 2017 19:02
" Created:			Nov 25 2016 23:16

" Only do this when not done yet for this buffer
if exists('b:did_cpp_ftplugin')
	finish
endif

" Don't load another plugin for this buffer
let b:did_cpp_ftplugin = 1

if exists('g:omnifunc_clang')
	let &l:omnifunc=g:omnifunc_clang
endif

" This is that delimate doesnt aut fill the newly added matchpairs
let b:delimitMate_matchpairs = '(:),[:],{:}'
let &l:define='^\(#\s*define\|[a-z]*\s*const\s*[a-z]*\)'

" Add mappings, unless the user didn't want this.
if !exists('no_plugin_maps') && !exists('no_c_maps')
	" Alternate between header and source file
	if exists(':A')
		nnoremap <buffer> <localleader>a :A<cr>
		" Open in alternate in a vertical window
		nnoremap <buffer> <localleader>A :AV<cr>
	else
		nnoremap <buffer> <localleader>a :call
					\ utils#SwitchHeaderSource()<cr>
	endif

	if has('unix') && has('nvim')
		nnoremap <buffer> <plug>help_under_cursor :call <SID>man_under_cursor()<cr>
	endif

	" if executable('lldb') && exists(':LLmode')
		" TODO-[RM]-(Wed May 23 2018 11:06): Make all of these guys <FX> mappings
		" nmap <buffer> <unique> <LocalLeader>db <Plug>LLBreakSwitch
		" vmap <F2> <Plug>LLStdInSelected
		" nnoremap <F4> :LLstdin<cr>
		" nnoremap <F5> :LLmode debug<cr>
		" nnoremap <S-F5> :LLmode code<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dc :LL continue<cr>
		" nnoremap <buffer> <unique> <LocalLeader>do :LL thread step-over<cr>
		" nnoremap <buffer> <unique> <LocalLeader>di :LL thread step-in<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dt :LL thread step-out<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dD :LLmode code<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dd :LLmode debug<cr>
		" nnoremap <buffer> <unique> <LocalLeader>dp :LL
		" \ print <C-R>=expand('<cword>')<cr>
		" nnoremap <S-F8> :LL process interrupt<cr>
		" nnoremap <F9> :LL print <C-R>=expand('<cword>')<cr>
		" vnoremap <F9> :<C-U>LL print <C-R>=lldb#util#get_selection()<cr><cr>
	" endif

	" if exists('g:clang_format_py')
		" nmap <buffer> <plug>format_code :execute('pyf ' . g:clang_format_py)<cr>
	" endif

	if exists(':GTestRun')
		" Attempt to guess executable test
		let g:gtest#gtest_command = (has('unix') ? '.' : '') .
					\ expand('%:p:r') . (has('unix') ? '' : '.exe')
		nnoremap <buffer> <localleader>tr :GTestRun<cr>
		nnoremap <buffer> <localleader>tt :GTestToggleEnable<cr>
		nnoremap <buffer> <localleader>tu :GTestRunUnderCursor<cr>
	endif

	call mappings#SetCscope()
endif

function! s:time_exe_win(...) abort
	if !exists(':Dispatch')
		echoerr 'Please install vim-dispatch'
		return
	endif

	let l:cmd = "Dispatch powershell -command \"& {&'Measure-Command' {.\\"

	for s in a:000
	  let l:cmd .= s . ' '
	endfor

	let l:cmd .= "}}\""

	exe l:cmd
endfunction

function! s:set_compiler_and_friends() abort
	if exists('b:current_compiler')
		return
	endif

	if has('unix')
		call linting#SetNeomakeClangMaker()
		call linting#SetNeomakeMakeMaker()
		if exists('g:LanguageClient_serverCommands')
			call autocompletion#AdditionalLspSettings()
		endif
		return 1
	endif

	" Commands for windows
	command! -buffer UtilsCompilerGcc
				\ execute("compiler gcc<bar>:setlocal makeprg=mingw32-make")
	command! -buffer UtilsCompilerBorland call linting#SetNeomakeBorlandMaker()
	command! -buffer UtilsCompilerMsbuild call linting#SetNeomakeMsBuildMaker()
	command! -buffer UtilsCompilerClangNeomake call linting#SetNeomakeClangMaker()
	nnoremap <buffer> <localleader>mg :UtilsCompilerGcc<cr>
	nnoremap <buffer> <localleader>mb :UtilsCompilerBorland<cr>
	nnoremap <buffer> <localleader>mm :UtilsCompilerMsbuild<cr>
	nnoremap <buffer> <localleader>mc :UtilsCompilerClangNeomake<cr>

	" Time runtime of a specific program. Pass as Argument executable with 
	" arguments. Pass as Argument executable with arguments. Example sep_calc.exe 
	" seprc.
	command! -nargs=+ -buffer UtilsTimeExec call s:time_exe_win(<f-args>)

	" Set compiler now depending on folder and system. Auto set the compiler
	let folder_name = expand('%:p:h')

	if folder_name =~? 'wings-dev'
		" Note: inside the '' is a pat which is a regex. That is why \\
		if folder_name =~? 'Onewings\\Source'
			call linting#SetNeomakeBorlandMaker()
			return
		endif
		call linting#SetNeomakeMsBuildMaker()
	else
		call linting#SetNeomakeClangMaker()
	endif
endfunction

function! s:man_under_cursor() abort
	if !exists(':Man')
		echoerr 'Man plugin not present'
		return -1
	endif

	execute ':vertical Man ' . expand('<cword>')
endfunction

" Setup Compiler and some specific stuff
call <SID>set_compiler_and_friends()

function! s:cctree_load_db() abort
	if !exists('g:ctags_output_dir') || empty('g:ctags_output_dir')
		echoerr '[cctree_load_db]: Failed to get g:ctags_output_dir path'
		return
	endif

	let l:db = g:ctags_output_dir . utils#GetFullPathAsName(getcwd())
	if !empty(glob(l:db . '.xref'))
		execute ':CCTreeLoadXRefDB ' . l:db . '.xref'
		return
	endif

	if !empty(glob(l:db . '.out'))
		execute ':CCTreeLoadDB ' . l:db . '.out'
		return
	else
		echoerr 'No cscope database for current path'
		return
	endif

	if !exists(':Denite')
		let l:db = input('Please enter full path to cscope.out like file: ')
	else
		let l:db = utils#DeniteYank(g:ctags_output_dir)
		if empty(l:db)
			echoerr '[cctree_load_db]: Failed to get Denite path'
			return
		endif
	endif
	
	execute ':CCTreeLoadDB ' . l:db
endfunction

function! s:cctree_save_xrefdb() abort
	if !exists('g:ctags_output_dir') || empty('g:ctags_output_dir')
		echoerr '[cctree_save_xrefdb]: Failed to get g:ctags_output_dir path'
		return
	endif

	let l:db = g:ctags_output_dir . utils#GetFullPathAsName(getcwd()) . '.xref'
	execute ':CCTreeSaveXRefDB ' . l:db
endfunction

" Setup AutoHighlight
" call utils#AutoHighlight()
