" File:ctags.vim
"	Description: All functions related to creation/deletion/update/loading of ctags and cscope
" Author:Reinaldo Molina <rmolin88@gmail.com>
" Version:1.0.0
" Last Modified: Thu May 25 2017 08:39
" Created: Sat Apr 01 2017 17:04

"	Your current directory should be at the root of you code
function! ctags#NvimSyncCtags() abort
	if !executable('rg')
		echomsg string("Ctags dependens on ripgrep. I know horrible")
		return
	endif

	if !executable('ctags')
		echomsg string("Ctags dependens on ctags. duh?!?!!")
		return
	endif

	if !executable('cscope')
		echomsg string("Ctags dependens on cscope")
		return
	endif

	" TODO.RM-Fri May 26 2017 15:35: Add a warning here that you are creating
	" tags and csscope for getcwd() folder
	let files_loc = g:std_data_path . "/ctags/"
	let cwd_rg = getcwd()
	if has('win32')
		let cwd_rg = substitute(cwd_rg, "\\", "/", "g") " Fix cwd for the rg command
		let files_loc = substitute(files_loc, "\\", "/", "g") " Fix cwd for the rg command
	endif

	echo "Create tags for '" . cwd_rg . "'?: (j|y)es (any)no"
	let response = getchar()
	if response == 121 || response == 106 " y|j
		echo "Loading..."
	else
		return

	endif

	let nvim_ft = &filetype
	if !s:create_cscope_files(files_loc, cwd_rg, nvim_ft)
		echomsg string("Failed to create cscope.files")
		return
	endif

	let ctags_lang = s:nvim_ft_to_ctags_ft(&filetype)

	" Create unique tag file name based on cwd_rg
	let folder_name = utils#GetPathFolderName(cwd_rg)
	if empty(folder_name)
		echomsg string("Failed to obtain folder_name")
		return
	endif

	if !s:create_tags('tags_' . folder_name, files_loc, ctags_lang, cwd_rg)
		echomsg "Failed to create tags file: tags_" . folder_name
		return
	endif

	if nvim_ft ==# 'cpp' || nvim_ft ==# 'c' || nvim_ft ==# 'java'
		" Create cscope db as well
		" TODO.RM-Thu May 25 2017 08:27: Do not kill connection until you determine that you are updating an existing tag
		let cs_db = folder_name . '.out'
		execute "lcd " . files_loc

		if !empty(glob(cs_db)) " If we are updating an existing tag. Close only that connection
			execute "silent! cs kill " . cs_db
		endif

		let cscope_cmd = 'cscope -f ' . cs_db . ' -bqi cscope.files'
		let res_cs = systemlist(cscope_cmd)
		if v:shell_error || getfsize(cs_db) < 1
			if !empty(res_cs)
				cexpr res_cs
			endif
			echomsg 'Cscope command failed'
			execute "lcd " . cwd_rg
			return
		endif

		execute "cs add " . cs_db
		execute "lcd " . cwd_rg
	endif
endfunction

" TODO.RM-Fri Mar 24 2017 16:49: This function is suppose to be async version of ctags#NvimSyncCtags
" Right now there is no support jobstart() in windows so its kinda difficult to make
function! ctags#NvimAsyncCtags() abort
	" if has('unix')
		" !rm cscope.files cscope.out cscope.po.out cscope.in.out
		" !find . -iregex '.*\.\(c\|cpp\|java\|cc\|h\|hpp\)$' > cscope.files
	" else
		" !del /F cscope.files cscope.in.out cscope.po.out cscope.out
		" !dir /b /s *.java *.cpp *.h *.hpp *.c *.cc *.cs > cscope.files
	" endif
	" First create the cscope.files
	let ft = Nvim_ft2ripgrep_ft()
	let cwd_rg = substitute(getcwd(), "\\", "/", "g") " Fix cwd for the rg command
	let callbacks = {
				\ 'on_stdout': function('s:JobHandler'),
				\ 'on_stderr': function('s:JobHandler'),
				\ 'on_exit': function('s:JobHandler'),
				\ 'cwd': g:std_data_path . '/ctags'
				\ }
	if executable('rg')
		let files_cmd = 'rg -t ' . ft . ' --files ' . "\"" . cwd_rg . "\"" . ' > cscope.files'
	endif

	call jobstart(files_cmd, callbacks)

	" let job1 = jobstart(['bash'], extend({'shell': 'shell 1'}, s:callbacks))
	" let job2 = jobstart(['bash', '-c', 'for i in {1..10}; do echo hello $i!; sleep 1; done'], extend({'shell': 'shell 2'}, s:callbacks))

	echomsg files_cmd

	" !cscope -b -q -i cscope.files
	" if !filereadable('cscope.out')
		" echoerr "Couldnt create cscope.out files"
		" return
	" endif

	" silent! cs kill -1
	" cs add cscope.out
	" " The extra=+q option is to highlight memebers
	" " Keep in mind that you are forcing the tags to be c++
	" silent !ctags -R -L cscope.files -f .tags --sort=yes --c++-kinds=+pl --fields=+iaS --extra=+q --language-force=C++
	" set tags+=.tags
endfunction

function! s:nvim_ft_to_rg_ft(ft) abort
	let rg_ft = a:ft
	if a:ft =~ 'vim'
		let rg_ft = 'vimscript'
	elseif a:ft =~ 'python'
		let rg_ft = 'py'
	endif
	return rg_ft
endfunction

" function! s:JobHandler(job_id, data, event) dict
	" " if a:event == 'stdout'
		" " let str = self.shell.' stdout: '.join(a:data)
	" " elseif a:event == 'stderr'
		" " let str = self.shell.' stderr: '.join(a:data)
	" " else
		" " let str = self.shell.' exited'
	" " endif

	" " call append(line('$'), str)
	" " cexpr str
	" cexpr printf('%s: %s',a:event,string(a:data))
" endfunction

function! s:nvim_ft_to_ctags_ft(ft) abort
	if a:ft == 'cpp'
		let lang = 'C++'
	elseif a:ft == 'vim'
		let lang = 'Vim'
	elseif a:ft == 'python'
		let lang = 'Python'
	elseif a:ft == 'java'
		let lang = 'Java'
	elseif a:ft == 'c'
		let lang = 'C'
	else
		return ''
	endif

	return lang
endfunction

" Original Version
function! s:update_ctags() abort
	if !executable('cscope') || !executable('ctags')
		echoerr "Please install cscope and/or ctags before using this application"
		return
	endif

	if executable('rg') && has('nvim') && has('python3') " Use asynch nvim call instead
		" call UpdateTagsRemote()
		" return
		" elseif has('python3')			" If python3 is available use it
		" if has('python3')			" If python3 is available use it
		call python#UpdateCtags()
		return
	endif

	silent! cs kill -1
	if has('unix')
		!rm cscope.files cscope.out cscope.po.out cscope.in.out
		!find . -iregex '.*\.\(c\|cpp\|java\|cc\|h\|hpp\)$' > cscope.files
	else
		!del /F cscope.files cscope.in.out cscope.po.out cscope.out
		!dir /b /s *.java *.cpp *.h *.hpp *.c *.cc *.cs > cscope.files
	endif
	!cscope -b -q -i cscope.files
	if !filereadable('cscope.out')
		echoerr "Couldnt create cscope.out files"
		return
	endif
	cs add cscope.out
	" The extra=+q option is to highlight memebers
	" Keep in mind that you are forcing the tags to be c++
	silent !ctags -R -L cscope.files -f .tags --sort=yes --c++-kinds=+pl --fields=+iaS --extra=+q --language-force=C++
	" set tags+=.tags
endfunction

function! s:list_tags_files() abort
	" Obtain full path list of all files in ctags folder
	let tags_loc = g:std_data_path . "/ctags/"
	let potential_tags = map(utils#ListFiles(tags_loc), "tags_loc . v:val")
	if len(potential_tags) == 0
		" echomsg tags_loc . " is empty"
		return
	endif

	return potential_tags
endfunction

" Creates cscope.files in ~\.cache\ctags\
function! s:create_cscope_files(files_loc, cwd_rg, nvim_ft) abort
	let rg_ft = s:nvim_ft_to_rg_ft(a:nvim_ft)
	" Get cscope files location
	let files_name = a:files_loc . "cscope.files"
	if has('win32')
		let files_name = substitute(files_name, "\\", "/", "g") " Fix cwd for the rg command
	endif
	" Cscope db are not being created properly therefore making cscope.files filetype specific no matter what
	let files_cmd = 'rg -t ' . rg_ft . ' --files ' .  a:cwd_rg .  ' > ' . files_name
	call delete(files_name)	 " Delete old/previous cscope.files
	" echomsg string(files_cmd)
	let res = ''
	if has('nvim')
		let res = systemlist(files_cmd)
	else
		silent! execute "!" . files_cmd
	endif
	if getfsize(files_name) < 1
		if !empty(res)
			cexpr res
		endif
		return
	endif
	return 1
endfunction

function! s:create_tags(tags_name, files_loc, ctags_lang, cwd_rg) abort
	if a:ctags_lang ==# 'C++'
		let ctags_cmd = "ctags -L cscope.files -f " . a:tags_name . " --sort=no
					\ --recurse=yes --c-kinds=+pl --c++-kinds=+pl --fields=+iaSl extras=+q"
	else
		let ctags_cmd = "ctags -L cscope.files -f " . a:tags_name . " --sort=no 
					\ --recurse=yes"
	endif

	" echomsg string(ctags_cmd) " Debugging
	execute "lcd " . a:files_loc
	let res = systemlist(ctags_cmd)

	if v:shell_error || getfsize(a:tags_name) < 1
		if !empty(res)
			cexpr res
		endif
		execute "lcd " . a:cwd_rg
		return
	endif

	call s:add_tags(a:tags_name)
	execute "lcd " . a:cwd_rg
	return 1
endfunction

function! ctags#LoadCscopeDatabse() abort
	if &modifiable == 0
		return
	endif

	" Local cscope.out has priority
	if !empty(glob('cscope.out'))
		cs add cscope.out
		return 1
	endif

	if !exists('g:root_dir') || empty(g:root_dir)
		let dir = expand('%:h')
	else
		let dir = g:root_dir
	endif

	let cs_db = utils#GetPathFolderName(dir)
	if empty(cs_db)
		" echomsg "Failed to obtain current folder name"
		return
	endif

	" Load tags as well
	call s:add_tags('tags_' . cs_db)

	let cs_db .= '.out'
	let cs_loc = g:std_data_path . '/ctags/' . cs_db

	redir => output
	execute 'silent cs show'
	redir END

	" If connection doesnt exist and file exists
	if output !~# cs_db && !empty(glob(cs_loc))
		execute 'silent cs add ' . cs_loc
	endif
endfunction

function! s:add_tags(tags_name) abort
	" Add new tag file if not already on the list
	let list_tags = tagfiles()
	let tag_present = 0
	for tag in list_tags
		if tag =~# a:tags_name
			let tag_present = 1
			break
		endif
	endfor
	if tag_present == 0
		execute "set tags+=" . g:std_data_path . '/ctags/' . a:tags_name
	endif
endfunction
