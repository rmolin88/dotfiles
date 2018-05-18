" File:				plugin.vim
" Description:Plugin specific settings
" Author:			Reinaldo Molina <rmolin88@gmail.com>
" Version:			2.0.1
" Last Modified: Thu Feb 22 2018 10:36
" Created: Fri Jun 02 2017 10:44

" List of pip requirements for your plugins:
" - pip3 install --user neovim psutil vim-vint
"   - on arch: python-vint python-neovin python-psutil
"   - However, pip is the preferred method. Not so sure becuase then you have to updated
"   manually.
" - These are mostly for python stuff
" - jedi mistune setproctitle jedi flake8 autopep8

" This function should not abort on error. Let continue configuring stuff
function! plugin#Config()
	if s:plugin_check() != 1
		return -1
	endif

	" Vim-Plug
		nnoremap <Leader>Pi :so %<bar>call plugin#Config()<bar>PlugInstall<CR>
		nnoremap <Leader>Pu :PlugUpdate<CR>
					\:PlugUpgrade<CR>
					\:UpdateRemotePlugins<CR>
		" installs plugins; append `!` to update or just :PluginUpdate
		nnoremap <Leader>Ps :PlugSearch<CR>
		" searches for foo; append `!` to refresh local cache
		nnoremap <Leader>Pl :PlugClean<CR>

	if exists('g:portable_vim')
		silent! call plug#begin(g:vim_plugins_path)
	else
		call plug#begin(g:vim_plugins_path)
	endif

	" This call must remain atop since sets the g:lightline variable to which other
	" plugins add to
	call plugin_lightline#config()

	call s:configure_async_plugins()

	call s:configure_ctrlp()

	" Lightline should be one of the very first ones so that plugins can later on add to
	" it
	if executable('mutt')
		Plug 'guanqun/vim-mutt-aliases-plugin'
	endif

	if executable('gpg')
		" This plugin doesnt work with gvim. Use only from cli
		Plug 'jamessan/vim-gnupg'
		let g:GPGUseAgent = 0
	endif

	" Possible values:
	" - ycm nvim_compl_manager shuogo autocomplpop completor asyncomplete neo_clangd
	" call autocompletion#SetCompl(has('nvim') ? 'nvim_compl_manager' : 'shuogo')
	call autocompletion#SetCompl('shuogo')

	" Possible values:
	" - chromatica easytags neotags color_coded clighter8
	call cpp_highlight#Set(has('nvim') ? 'neotags' : '')

	" Possible values:
	" - neomake ale
	call linting#Set('neomake')

	" Neovim exclusive plugins
	if has('nvim')
		" Note: Thu Aug 24 2017 21:03 This plugin is actually required for the git
		" plugin to work in neovim
		Plug 'radenling/vim-dispatch-neovim'
		" nvim-qt on unix doesnt populate has('gui_running')
		Plug 'equalsraf/neovim-gui-shim'
		if executable('lldb') && has('unix')
			Plug 'critiqjo/lldb.nvim'
			" All mappings moved to c.vim
			" Note: Remember to always :UpdateRemotePlugins
			"TODO.RM-Sun May 21 2017 01:14: Create a ftplugin/lldb.vim to disable
			"folding
		endif
	endif

	" Possible Replacement `asyncvim`
	Plug 'tpope/vim-dispatch'
	" Vim cpp syntax highlight
		let g:cpp_class_scope_highlight = 1
		let g:cpp_member_variable_highlight = 1
		let g:cpp_class_decl_highlight = 1
		let g:cpp_concepts_highlight = 1
	Plug 'justinmk/vim-syntax-extra'

	call s:configure_vim_table_mode()

	call s:configure_vim_utils()

	" misc
	if executable('git')
		Plug 'chrisbra/vim-diff-enhanced'
			let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=patience")'
	endif

	" Options: netranger, nerdtree
	call s:configure_file_browser((executable('ranger') ? 'ranger' : 'nerdtree'))

	call s:configure_nerdcommenter()

	Plug 'chrisbra/Colorizer', { 'for' : [ 'css','html','xml' ] }
		let g:colorizer_auto_filetype='css,html,xml'
	Plug 'tpope/vim-repeat'
	Plug 'tpope/vim-surround'

	" Fold stuff
	" Fri May 19 2017 12:50 I have tried many times to get 'fdm=syntax' to work
	" on large files but its just not possible. Too slow.
	Plug 'Konfekt/FastFold', { 'on' : 'FastFold' }
		" Stop updating folds everytime I save a file
		let g:fastfold_savehook = 0
		" To update folds now you have to do it manually pressing 'zuz'
		let g:fastfold_fold_command_suffixes =
					\['x','X','a','A','o','O','c','C','r','R','m','M','i','n','N']

	" Wed Apr 04 2018 12:55: Rooter used to be on demand but I took it.
	" - In order to make use of its FindRootDirectory() function
	Plug 'airblade/vim-rooter'
		let g:rooter_manual_only = 1
		nmap <plug>cd_root :Rooter<CR>
		let g:rooter_use_lcd = 1
		let g:rooter_patterns = ['.git/', '.svn/', 'Source/']
		" nnoremap <Leader>cr :call utils#RooterAutoloadCscope()<CR>

	Plug 'Raimondi/delimitMate'
		let g:delimitMate_expand_cr = 1
		let g:delimitMate_expand_space = 1
		let g:delimitMate_jump_expansion = 1
		" imap <expr> <CR> <Plug>delimitMateCR

	Plug 'sbdchd/neoformat', { 'on' : 'Neoformat' }
		let g:neoformat_c_clangformat = {
					\ 'exe': 'clang-format',
					\ 'args': ['-style=file'],
					\ }
		let g:neoformat_cpp_clangformat = {
					\ 'exe': 'clang-format',
					\ 'args': ['-style=file'],
					\ }

	" cpp
	if get(g:, 'tagbar_safe_to_use', 1)
		call s:configure_tagbar()
	endif

	" python
		" Plug 'python-mode/python-mode', { 'for' : 'python' } " Extremely
		" aggressive

	" pip install isort --user
	Plug 'fisadev/vim-isort', { 'for' : 'python' }
		let g:vim_isort_map = ''
		let g:vim_isort_python_version = 'python3'

	" java
	Plug 'mattn/vim-javafmt', { 'for' : 'java' }
	Plug 'tfnico/vim-gradle', { 'for' : 'java' }
	Plug 'artur-shaik/vim-javacomplete2', { 'branch' : 'master', 'for' : 'java' }
		let g:JavaComplete_ClosingBrace = 1
		let g:JavaComplete_EnableDefaultMappings = 0
		let g:JavaComplete_ImportSortType = 'packageName'
		let g:JavaComplete_ImportOrder = ['android.', 'com.', 'junit.', 'net.', 'org.', 'java.', 'javax.']

	" Autocomplete
	call s:configure_snippets()

	" Version control
	Plug 'tpope/vim-fugitive'
		" Fugitive <Leader>g?
		" nmap here is needed for the <C-n> to work. Otherwise it doesnt know what
		" it means
		nmap <Leader>gs :Gstatus<CR><C-w>L<C-n>
		nnoremap <Leader>gps :Gpush<CR>
		nnoremap <Leader>gpl :Gpull<CR>
		nnoremap <Leader>gl :silent Glog<CR>
					\:copen 20<CR>

	Plug 'mhinz/vim-signify'
		" Mappings are ]c next differences
		" Mappings are [c prev differences
		" Gets enabled when you call SignifyToggle
		let g:signify_disable_by_default = 1
		let g:signify_vcs_list = [ 'git', 'svn' ]

	Plug 'juneedahamed/svnj.vim', { 'on' : 'SVNStatus' }
		let g:svnj_allow_leader_mappings=0
		let g:svnj_cache_dir = g:std_cache_path
		let g:svnj_browse_cache_all = 1
		let g:svnj_custom_statusbar_ops_hide = 0
		nnoremap <silent> <leader>vs :SVNStatus q<CR>
		nnoremap <silent> <leader>vo :SVNLog .<CR>

	" colorschemes
	Plug 'morhetz/gruvbox' " colorscheme gruvbox
	Plug 'NLKNguyen/papercolor-theme'

		let g:PaperColor_Theme_Options =
					\ {
					\		'language':
					\		{
					\			'python': { 'highlight_builtins': 1 },
					\			'c': { 'highlight_builtins': 1 },
					\			'cpp': { 'highlight_standard_library': 1 },
					\		},
					\		'theme':
					\		{
					\		 	'default': { 'transparent_background': 0 }
					\		}
					\ }
	
	" Mon Jan 08 2018 15:08: Do not load these schemes unless they are going to be used
	" Sun May 07 2017 16:25 - Gave it a try and didnt like it
	" Plug 'icymind/NeoSolarized'
	" Sat Oct 14 2017 15:50: Dont like this one either.
	" Plug 'google/vim-colorscheme-primary'
	" Sat Oct 14 2017 15:59: Horrible looking
	" Plug 'joshdick/onedark.vim'
	" Plug 'altercation/vim-colors-solarized'
	" Plug 'jnurmine/Zenburn'

	" Magnum is required by vim-radical. use with gA
	Plug 'glts/vim-magnum', { 'on' : '<Plug>RadicalView' }
	Plug 'glts/vim-radical', { 'on' : '<Plug>RadicalView' }
		nnoremap gA <Plug>RadicalView

	" W3M - to view cpp-reference help
	if executable('w3m')
		" TODO-[RM]-(Thu Sep 14 2017 21:12): No chance to get this working on windows
		Plug 'yuratomo/w3m.vim'
			let g:w3m#history#save_file = g:std_cache_path . '/vim_w3m_hist'
			" Mon Sep 18 2017 22:37: To open html file do `:W3mLocal %'
	endif

	call s:configure_vim_sneak()

	Plug 'waiting-for-dev/vim-www'
		" TODO-[RM]-(Thu Sep 14 2017 21:02): Update this here
		let g:www_map_keys = 0
		let g:www_launch_cli_browser_command = g:browser_cmd . ' {{URL}}'
		nnoremap gG :Wcsearch duckduckgo <C-R>=expand("<cword>")<CR><CR>
		vnoremap gG "*y:call www#www#user_input_search(1, @*)<CR>

	if has('win32')
		Plug 'PProvost/vim-ps1', { 'for' : 'ps1' }
	endif

	Plug 'vim-pandoc/vim-pandoc', { 'on' : 'Pandoc' }
	Plug 'vim-pandoc/vim-pandoc-syntax', { 'on' : 'Pandoc' }
		" You might be able to get away with xelatex in unix
		let g:pandoc#command#latex_engine = 'pdflatex'
		let g:pandoc#folding#fdc=0
		let g:pandoc#keyboard#use_default_mappings=0
		" Pandoc pdf --template eisvogel --listings
		" PandocTemplate save eisvogel
		" Pandoc #eisvogel

	" Plug 'sheerun/vim-polyglot' " A solid language pack for Vim.
	Plug 'matze/vim-ini-fold', { 'for': 'dosini' }

	" Not being used but kept for dependencies
	Plug 'rbgrouleff/bclose.vim'

	Plug 'godlygeek/tabular'
		let g:no_default_tabular_maps = 1

	" This plugin depends on 'godlygeek/tabular'
	Plug 'plasticboy/vim-markdown', { 'for' : 'markdown' }
		let g:vim_markdown_no_default_key_mappings = 1
		let g:vim_markdown_toc_autofit = 1
		let g:tex_conceal = ''
		let g:vim_markdown_math = 1
		let g:vim_markdown_folding_level = 2
		let g:vim_markdown_frontmatter = 1
		let g:vim_markdown_new_list_item_indent = 0

	" Sun Sep 10 2017 20:44 Depends on plantuml being installed
	" If you want dont want to image preview after loading the plugin put the
	" comment:
	"		'no-preview
	"	in your file
	Plug 'scrooloose/vim-slumlord', { 'on' : 'UtilsUmlInFilePreview' }

	Plug 'merlinrebrovic/focus.vim', { 'on' : '<Plug>FocusModeToggle' }
			let g:focus_use_default_mapping = 0
			nmap <Leader>tf <Plug>FocusModeToggle

	Plug 'dbmrq/vim-ditto', { 'for' : 'markdown' }
		let g:ditto_dir = g:std_data_path
		let g:ditto_file = 'ditto-ignore.txt'

	" TODO-[RM]-(Sun Sep 10 2017 20:27): Dont really like it
	call s:configure_vim_wordy()

	" TODO-[RM]-(Sun Sep 10 2017 20:26): So far only working on linux
	Plug 'beloglazov/vim-online-thesaurus', { 'on' : 'OnlineThesaurusCurrentWord' }
		let g:online_thesaurus_map_keys = 0

	" Autocorrect mispellings on the fly
	Plug 'panozzaj/vim-autocorrect', { 'for' : 'markdown' }
	" Disble this file by removing its function call from autload/markdown.vim

	" Sun Sep 10 2017 20:44 Depends on languagetool being installed
	if !empty('g:languagetool_jar')
		Plug 'dpelle/vim-LanguageTool', { 'for' : 'markdown' }
	endif

	call s:configure_pomodoro()

	Plug 'chrisbra/csv.vim', { 'for' : 'csv' }
		let g:no_csv_maps = 1
    let g:csv_strict_columns = 1
		" augroup Csv_Arrange
			" autocmd!
			" autocmd BufWritePost *.csv call CsvArrangeColumns()
		" augroup END
		" let g:csv_autocmd_arrange      = 1
		" let g:csv_autocmd_arrange_size = 1024*1024

	" Thu Jan 25 2018 17:36: Not that useful. More useful is mapping N to center the screen as well
	" Plug 'google/vim-searchindex'

	" Documentation plugins
	Plug 'rhysd/devdocs.vim', { 'on' : '<Plug>(devdocs-under-cursor)' }
		" Sample mapping in a ftplugin/*.vim
		nmap ghd <Plug>(devdocs-under-cursor)


	Plug 'KabbAmine/zeavim.vim', {'on': [
				\	'Zeavim', 'Docset',
				\	'<Plug>Zeavim',
				\	'<Plug>ZVVisSelection',
				\	'<Plug>ZVKeyDocset',
				\	'<Plug>ZVMotion'
				\ ]}
		let g:zv_disable_mapping = 1
		nmap ghz <Plug>Zeavim

	" Only for arch
	if executable('dasht')
		Plug 'sunaku/vim-dasht', { 'on' : 'Dasht' }
			" When in C++, also search C, Boost, and OpenGL:
			let g:dasht_filetype_docsets['cpp'] = ['^c$', 'boost', 'OpenGL']
	endif

	Plug 'itchyny/calendar.vim', { 'on' : 'Calendar' }
		let g:calendar_google_calendar = 1
		let g:calendar_cache_directory = g:std_cache_path . '/calendar.vim/'

	" Tue Oct 31 2017 11:30: Needs to be loaded last
	Plug 'ryanoasis/vim-devicons'
		let g:WebDevIconsUnicodeDecorateFolderNodes = 1
		let g:DevIconsEnableFoldersOpenClose = 1

	Plug 'chaoren/vim-wordmotion'
		let g:wordmotion_spaces = '_-.'
		let g:wordmotion_mappings = {
					\ 'w' : '<c-f>',
					\ 'b' : '<c-b>',
					\ 'e' : '',
					\ 'ge' : '',
					\ 'aw' : '',
					\ 'iw' : '',
					\ '<C-R><C-W>' : ''
					\ }

	" Software caps lock. imap <c-l> ToggleSoftwareCaps
	Plug 'tpope/vim-capslock'

	Plug 'hari-rangarajan/CCTree'

	Plug 'bronson/vim-trailing-whitespace'
		let g:extra_whitespace_ignored_filetypes = []

	Plug 'mhinz/vim-grepper'
		nmap <LocalLeader>s <plug>(GrepperOperator)
		xmap <LocalLeader>s <plug>(GrepperOperator)
		if exists('g:lightline')
			let g:lightline.active.left[2] += [ 'grepper' ]
			let g:lightline.component_function['grepper'] = 'grepper#statusline'
		endif

	" Plug 'jalvesaq/Nvim-R'
		" Tue Apr 24 2018 14:40: Too agressive with mappings. Very hard to get it to work.
		" not seeing the huge gains at the moment. Better of just using neoterm at the
		" moment.
		" Installing manually:
		" R CMD build /path/to/Nvim-R/R/nvimcom
		" R CMD INSTALL nvimcom_0.9-39.tar.gz
		" nmap <LocalLeader>r <Plug>RStart
		" imap <LocalLeader>r <Plug>RStart
		" vmap <LocalLeader>r <Plug>RStart

	Plug 'fourjay/vim-flexagon'

	" Abstract a region to its own buffer for editting. Then save and it will back
	Plug 'chrisbra/NrrwRgn', { 'on' : 'NR' }

	" Tue May 15 2018 17:44: All of these replaced by a single plugin
	" - Not so fast cowboy. This plugin is updated ever so ofen. Plus you dont get
	"   options. Pretty much only the defaults. Its a good source to find syntax plugins
	"   but that's all.
	" Plug 'sheerun/vim-polyglot'
	Plug 'PotatoesMaster/i3-vim-syntax'
	Plug 'elzr/vim-json', { 'for' : 'json' }
	Plug 'aklt/plantuml-syntax', { 'for' : 'plantuml' }
	Plug 'octol/vim-cpp-enhanced-highlight', { 'for' : [ 'c' , 'cpp' ] }

	" All of your Plugins must be added before the following line
	call plug#end()            " required

	return 1
endfunction

function! s:plugin_check() abort
	" If already loaded files cool
	if exists('*plug#begin')
		return 1
	endif

	if !empty(glob(g:plug_path))
		" vim-plug exists already
		execute 'source ' . g:plug_path
		return 1
	endif

	let link = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	if utils#DownloadFile(g:plug_path, link) != 1
		return -1
	endif

	augroup install_plugin
		autocmd!
		autocmd VimEnter * :PlugInstall
	augroup END

	" Source the newly downloaded file
	execute 'source ' . g:plug_path
	" Return 1 so that Plugs get loaded and install later
	return 1
endfunction

" Called on augroup VimEnter search augroup.vim
function! plugin#AfterConfig() abort
	if exists('g:loaded_deoplete')
		call deoplete#custom#source('javacomplete2', 'mark', '')
		call deoplete#custom#source('_', 'matchers', ['matcher_full_fuzzy'])
		" c c++
		call deoplete#custom#source('clang2', 'mark', '')
	endif

	" Plugin function names are never detected. Only plugin commands
	if exists('g:loaded_denite')
		" Change mappings.
		call denite#custom#map('insert','<C-j>','<denite:move_to_next_line>','noremap')
		call denite#custom#map('insert','<C-k>','<denite:move_to_previous_line>','noremap')
		call denite#custom#map('insert','<C-v>','<denite:do_action:vsplit>','noremap')
		call denite#custom#map('insert','<C-d>','<denite:scroll_window_downwards>','noremap')
		call denite#custom#map('insert','<C-u>','<denite:scroll_window_upwards>','noremap')
		" Change options
		call denite#custom#option('default', 'winheight', 15)
		call denite#custom#option('_', 'highlight_matched_char', 'Function')
		call denite#custom#option('_', 'highlight_matched_range', 'Function')
		if executable('rg')
			call denite#custom#var('file_rec', 'command',
						\ ['rg', '--glob', '!.{git,svn}', '--files', '--no-ignore',
						\ '--smart-case', '--follow', '--hidden'])
			" Ripgrep command on grep source
			call denite#custom#var('grep', 'command', ['rg'])
			call denite#custom#var('grep', 'default_opts',
						\ ['--vimgrep', '--no-heading', '--smart-case', '--follow', '--hidden',
						\ '--glob', '!.{git,svn}'])
			call denite#custom#var('grep', 'recursive_opts', [])
			call denite#custom#var('grep', 'pattern_opt', ['--regexp'])
			call denite#custom#var('grep', 'separator', ['--'])
			call denite#custom#var('grep', 'final_opts', [])
		elseif executable('ag')
			call denite#custom#var('file_rec', 'command',
						\ ['ag', '--follow', '--nocolor', '--nogroup', '-g', '--hidden', ''])
			call denite#custom#var('grep', 'command', ['ag'])
			call denite#custom#var('grep', 'default_opts',
						\ ['--vimgrep', '--no-heading', '--smart-case', '--follow', '--hidden',
						\ '--glob', '!.{git,svn}'])
			call denite#custom#var('grep', 'recursive_opts', [])
			call denite#custom#var('grep', 'pattern_opt', [])
			call denite#custom#var('grep', 'separator', ['--'])
			call denite#custom#var('grep', 'final_opts', [])
		endif
		" Change ignore_globs
		call denite#custom#filter('matcher_ignore_globs', 'ignore_globs',
					\ [ '.git/', '.svn/', '.ropeproject/', '__pycache__/',
					\   'venv/', 'images/', '*.min.*', 'img/', 'fonts/', 'Obj/', '*.obj'])
	endif

	" Run neomake everytime you save a file
	if exists('g:loaded_neomake')
		call neomake#configure#automake('w')
	endif

	if exists('g:loaded_grepper')
		if executable('rg')
			nnoremap <LocalLeader>s :Grepper -tool rg<cr>
			if has('unix')
				let g:grepper.rg.grepprg .= " --smart-case --follow --fixed-strings --hidden --iglob '!.{git,svn}'"
			else
				let g:grepper.rg.grepprg .= ' --smart-case --follow --fixed-strings --hidden --iglob !.{git,svn}'
			endif
		else
			nnoremap <LocalLeader>s :Grepper<cr>
		endif
		if executable('pdfgrep')
			let g:grepper.tools += ['pdfgrep']
			let g:grepper.pdfgrep = {
						\ 'grepprg':    'pdfgrep --ignore-case --page-number --recursive --context 1',
						\ }
		endif
	endif
endfunction

function! s:configure_ctrlp() abort
	Plug 'ctrlpvim/ctrlp.vim'
		nmap <plug>buffer_browser :CtrlPBuffer<CR>
		nmap <plug>mru_browser :CtrlPMRU<CR>
		let g:ctrlp_map = ''
		let g:ctrlp_cmd = 'CtrlPMRU'
		" submit ? in CtrlP for more mapping help.
		let g:ctrlp_lazy_update = 1
		let g:ctrlp_show_hidden = 1
		let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:10,results:10'
		" It says cache dir but dont want to keep loosing history everytime cache gets cleaned up
		" Fri Jan 05 2018 14:38: Now that denite's file_rec is working much better no need
		" to keep this innacurrate list of files around. Rely on it less.
		" Thu May 03 2018 05:55: Giving ctrlp another chance. There is like a 1 sec delay
		" with Denite file_mru and file/old doesnt really work.
		let g:ctrlp_cache_dir = g:std_data_path . '/ctrlp'
		let g:ctrlp_working_path_mode = 'wra'
		let g:ctrlp_max_history = &history
		let g:ctrlp_clear_cache_on_exit = 0
		let g:ctrlp_switch_buffer = 0
		let g:ctrlp_mruf_max = 10000
		if has('win32')
			let g:ctrlp_mruf_exclude = '^C:\\dev\\tmp\\Temp\\.*'
			set wildignore+=*\\.git\\*,*\\.hg\\*,*\\.svn\\*  " Windows ('noshellslash')
			let g:ctrlp_custom_ignore = {
						\ 'dir':  '\v[\/]\.(git|hg|svn)$',
						\ 'file': '\v\.(tlog|log|db|obj|o|exe|so|dll|dfm)$',
						\ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
						\ }
		else
			let g:ctrlp_mruf_exclude =  '/tmp/.*\|/temp/.*'
			set wildignore+=*/.git/*,*/.hg/*,*/.svn/*        " Linux/MacOSX
			let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
		endif
		let g:ctrlp_prompt_mappings = {
					\ 'PrtBS()': ['<bs>', '<c-h>'],
					\ 'PrtCurLeft()': ['<left>', '<c-^>'],
					\ 'PrtCurRight()': ['<right>'],
					\ }
		" Lightline settings
		if exists('g:lightline')
			let g:lightline.active.left[2] += [ 'ctrlpmark' ]
			let g:lightline.component_function['ctrlpmark'] = string(function('s:ctrlp_lightline_mark'))

			let g:ctrlp_status_func = {
						\ 'main': string(function('s:ctrlp_lightline_func1')),
						\ 'prog': string(function('s:ctrlp_lightline_func2')),
						\ }
		endif
endfunction

function! s:ctrlp_lightline_mark() abort
	if expand('%:t') !~# 'ControlP' || !has_key(g:lightline, 'ctrlp_item')
		return ''
	endif

	call lightline#link('iR'[g:lightline.ctrlp_regex])
	return lightline#concatenate([g:lightline.ctrlp_prev, g:lightline.ctrlp_item
				\ , g:lightline.ctrlp_next], 0)
endfunction

function! s:ctrlp_lightline_func1(focus, byfname, regex, prev, item, next, marked) abort
	let g:lightline.ctrlp_regex = a:regex
	let g:lightline.ctrlp_prev = a:prev
	let g:lightline.ctrlp_item = a:item
	let g:lightline.ctrlp_next = a:next
	return lightline#statusline(0)
endfunction

function! s:ctrlp_lightline_func2(str) abort
	return lightline#statusline(0)
endfunction


function! s:configure_async_plugins() abort
	if !has('nvim') && v:version < 800
		echomsg 'No async support in this version. No neoterm, no denite.'
		return -1
	endif

	Plug 'kassio/neoterm'
		let g:neoterm_use_relative_path = 1
		let g:neoterm_default_mod = 'vertical'
		let g:neoterm_autoinsert=1
		nnoremap <Plug>terminal_toggle :Ttoggle<CR>
		vmap <Plug>terminal_selection_send :TREPLSendSelection<CR>

	Plug 'Shougo/denite.nvim', { 'do' : has('nvim') ? ':UpdateRemotePlugins' : '' }
		" TODO-[RM]-(Wed Jan 10 2018 15:46): Come up with new mappings for these commented
		" out below
		" nnoremap <C-S-;> :Denite command_history<CR>
		" nnoremap <C-S-h> :Denite help<CR>
		" nmap <plug>mru_browser :Denite file_mru<CR>
		" Wed Jan 10 2018 15:46: Have tried several times to use denite buffer but its
		" just too awkard. Kinda slow and doesnt show full path.
		" nnoremap <S-k> :Denite buffer<CR>

		" It includes file_mru source for denite.nvim.
		Plug 'Shougo/neomru.vim'
endfunction

function! s:configure_vim_table_mode() abort
	Plug 'dhruvasagar/vim-table-mode', { 'on' : 'TableModeToggle' }
	" To start using the plugin in the on-the-fly mode use :TableModeToggle
	" mapped to <Leader>tm by default Enter the first line, delimiting columns
	" by the | symbol. In the second line (without leaving Insert mode), enter
	" | twice For Markdown-compatible tables use
	let g:table_mode_corner='|'
	" let g:table_mode_corner = '+'
	let g:table_mode_align_char = ':'
	" TODO.RM-Wed Jul 19 2017 21:10: Fix here these mappings are for terminal
	let g:table_mode_map_prefix = '<LocalLeader>t'
	let g:table_mode_disable_mappings = 1
	nnoremap <Leader>ta :TableModeToggle<CR>
	" <Leader>tr	Realigns table columns
endfunction

function! s:configure_vim_utils() abort
	Plug g:location_vim_utils
	" Load the rest of the stuff and set the settings
	let g:svn_repo_url = 'svn://odroid@copter-server/'
	let g:svn_repo_name = 'UnrealEngineCourse/BattleTanks_2/'
	nnoremap <Leader>vw :call SVNSwitch<CR>
	nnoremap <Leader>vb :call SVNCopy<CR>

	nnoremap <Leader>of :Dox<CR>
	" Other commands
	" command! -nargs=0 DoxLic :call <SID>DoxygenLicenseFunc()
	" command! -nargs=0 DoxAuthor :call <SID>DoxygenAuthorFunc()
	" command! -nargs=1 DoxUndoc :call <SID>DoxygenUndocumentFunc(<q-args>)
	" command! -nargs=0 DoxBlock :call <SID>DoxygenBlockFunc()
	let g:DoxygenToolkit_paramTag_pre=	'	'
	let g:DoxygenToolkit_returnTag=			'Returns:   '
	let g:DoxygenToolkit_blockHeader=''
	let g:DoxygenToolkit_blockFooter=''
	let g:DoxygenToolkit_authorName='Reinaldo Molina <rmolin88 at gmail dot com>'
	let g:DoxygenToolkit_authorTag =	'Author:				'
	let g:DoxygenToolkit_fileTag =		'File:					'
	let g:DoxygenToolkit_briefTag_pre='Description:		'
	let g:DoxygenToolkit_dateTag =		'Last Modified: '
	let g:DoxygenToolkit_versionTag = 'Version:				'
	let g:DoxygenToolkit_commentType = 'C++'
	let g:DoxygenToolkit_versionString = '0.0.0'

	let g:ctags_create_spell=1
	let g:ctags_spell_script= g:location_vim_utils . '/tagstospl.py'
	" Cscope databases and spell files will only be created for the following filetypes
	let g:ctags_use_spell_for = ['c', 'cpp']
	let g:ctags_use_cscope_for = ['c', 'cpp', 'java']
endfunction

function! s:configure_nerdcommenter() abort
	Plug 'scrooloose/nerdcommenter'
	" NerdCommenter
	let g:NERDSpaceDelims=1  " space around comments
	let g:NERDUsePlaceHolders=0 " avoid commenter doing weird stuff
	let g:NERDCommentWholeLinesInVMode=2
	let g:NERDCreateDefaultMappings=0 " Eliminate default mappings
	let g:NERDRemoveAltComs=1 " Remove /* comments
	let g:NERD_c_alt_style=0 " Do not use /* on C nor C++
	let g:NERD_cpp_alt_style=0
	let g:NERDMenuMode=0 " no menu
	let g:NERDCustomDelimiters = {
				\ 'vim': { 'left': '"', 'right': '', 'leftAlt': '#', 'rightAlt': ''},
				\ 'markdown': { 'left': '//', 'right': '' },
				\ 'dosini': { 'left': ';', 'leftAlt': '//', 'right': '', 'rightAlt': '' },
				\ 'csv': { 'left': '#', 'right': '' },
				\ 'plantuml': { 'left': "'", 'right': '', 'leftAlt': "/'", 'rightAlt': "'/"},
				\ 'wings_syntax': { 'left': '//', 'right': '', 'leftAlt': '//', 'rightAlt': '' },
				\ 'sql': { 'left': '--', 'right': '', 'leftAlt': 'REM', 'rightAlt': '' }
				\ }

	let g:NERDTrimTrailingWhitespace = 1
endfunction

function! s:configure_tagbar() abort
	Plug 'majutsushi/tagbar'
		let g:tagbar_ctags_bin = 'ctags'
		let g:tagbar_autofocus = 1
		let g:tagbar_show_linenumbers = 2
		let g:tagbar_map_togglesort = 'r'
		let g:tagbar_map_nexttag = '<c-j>'
		let g:tagbar_map_prevtag = '<c-k>'
		let g:tagbar_map_openallfolds = '<c-n>'
		let g:tagbar_map_closeallfolds = '<c-c>'
		let g:tagbar_map_togglefold = '<c-x>'
		let g:tagbar_autoclose = 1

	" These settings do not use patched fonts
	" Fri Feb 02 2018 15:38: Its number one thing slowing down vim right now.
	let g:lightline.active.left[2] += [ 'tagbar' ]
	let g:lightline.component_function['tagbar'] = string(function('s:tagbar_lightline'))
endfunction

function! s:tagbar_lightline() abort
	try
		let ret =  tagbar#currenttag('%s','')
	catch
		return ''
	endtry
	return empty(ret) ? '' :
				\ (exists('g:valid_device') ? "\uf02b" : '')
				\ . ' ' . ret
endfunction

function! s:tagbar_statusline_func(current, sort, fname, ...) abort
	let g:lightline.fname = a:fname
	return lightline#statusline(0)
endfunction

function! s:configure_snippets() abort
	Plug 'Shougo/neosnippet'
	imap <C-k>     <Plug>(neosnippet_expand_or_jump)
	smap <C-k>     <Plug>(neosnippet_expand_or_jump)
	xmap <C-k>     <Plug>(neosnippet_expand_target)
	smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
				\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
	" Tell Neosnippet about the other snippets
	let g:neosnippet#snippets_directory= [ g:vim_plugins_path . '/vim-snippets/snippets', g:location_vim_utils . '/snippets/', ]
	" Fri Oct 20 2017 21:47: Not really data but cache
	let g:neosnippet#data_directory = g:std_cache_path . '/neosnippets'
	" Used by nvim-completion-mgr
	let g:neosnippet#enable_completed_snippet=1

	" Only contain snippets
	Plug 'Shougo/neosnippet-snippets'
	Plug 'honza/vim-snippets'
	let g:snips_author = 'Reinaldo Molina'
	let g:snips_email = 'rmolin88 at gmail dot com'
	let g:snips_github = 'rmolin88'
endfunction

function! s:configure_vim_sneak() abort
	Plug 'justinmk/vim-sneak'
	" replace 'f' with 1-char Sneak
	nmap f <Plug>Sneak_f
	nmap F <Plug>Sneak_F
	xmap f <Plug>Sneak_f
	xmap F <Plug>Sneak_F
	omap f <Plug>Sneak_f
	omap F <Plug>Sneak_F
	" replace 't' with 1-char Sneak
	nmap t <Plug>Sneak_t
	nmap T <Plug>Sneak_T
	xmap t <Plug>Sneak_t
	xmap T <Plug>Sneak_T
	omap t <Plug>Sneak_t
	omap T <Plug>Sneak_T
	xnoremap s s
endfunction

function! s:configure_vim_wordy() abort
	Plug 'reedes/vim-wordy', { 'for' : 'markdown' }
	let g:wordy#ring = [
				\ 'weak',
				\ ['being', 'passive-voice', ],
				\ 'business-jargon',
				\ 'weasel',
				\ 'puffery',
				\ ['problematic', 'redundant', ],
				\ ['colloquial', 'idiomatic', 'similies', ],
				\ 'art-jargon',
				\ ['contractions', 'opinion', 'vague-time', 'said-synonyms', ],
				\ 'adjectives',
				\ 'adverbs',
				\ ]
endfunction

function! s:configure_pomodoro() abort
	Plug 'rmolin88/pomodoro.vim'
	" let g:pomodoro_show_time_remaining = 0
	" let g:pomodoro_time_slack = 1
	" let g:pomodoro_time_work = 1
	let g:pomodoro_use_devicons = 1
	if executable('twmnc')
		let g:pomodoro_notification_cmd = 'twmnc -t Vim -i nvim -c "Pomodoro done"
					\ && mpg123 ~/.config/dotfiles/notification_sounds/cool_notification1.mp3 2>/dev/null&'
	elseif executable('dunst')
		let g:pomodoro_notification_cmd = "notify-send 'Pomodoro' 'Session ended'
					\ && mpg123 ~/.config/dotfiles/notification_sounds/cool_notification1.mp3 2>/dev/null&"
	elseif executable('powershell')
		let notif = $APPDATA . '/dotfiles/scripts/win_vim_notification.ps1'
		if filereadable(notif)
			let g:pomodoro_notification_cmd = 'powershell ' . notif
		endif
	endif
	let g:pomodoro_log_file = g:std_data_path . '/pomodoro_log'

	if exists('g:lightline')
		let g:lightline.active.left[2] += [ 'pomodoro' ]
		let g:lightline.component_function['pomodoro'] = 'pomo#status_bar'
	endif
endfunction

" choice - One of netranger, nerdtree, or ranger
function! s:configure_file_browser(choice) abort
	" file_browser
	" Wed May 03 2017 11:31: Tried `vifm` doesnt work in windows. Doesnt
	" follow `*.lnk` shortcuts. Not close to being Replacement for `ranger`.
	" Main reason it looks appealing is that it has support for Windows. But its
	" not very good
	" Fri Feb 23 2018 05:16: Also tried netranger. Not that great either. Plus only
	" supports *nix.


	if a:choice ==# 'nerdtree'
		nnoremap <plug>file_browser :NERDTree<CR>

		Plug 'scrooloose/nerdtree', { 'on' : 'NERDTree' }
		Plug 'Xuyuanp/nerdtree-git-plugin', { 'on' : 'NERDTree' }
		" Nerdtree (Dont move. They need to be here)
		let g:NERDTreeShowBookmarks=1  " B key to toggle
		let g:NERDTreeShowLineNumbers=1
		let g:NERDTreeShowHidden=1 " i key to toggle
		let g:NERDTreeQuitOnOpen=1 " AutoClose after openning file
		let g:NERDTreeBookmarksFile= g:std_data_path . '/.NERDTreeBookmarks'
	elseif a:choice ==# 'netranger'
		Plug 'ipod825/vim-netranger'
		let g:NETRRootDir = g:std_data_path . '/netranger/'
		let g:NETRIgnore = [ '.git', '.svn' ]
	elseif a:choice ==# 'ranger'
		nmap <plug>file_browser :RangerCurrentDirectory<CR>
		Plug 'francoiscabrol/ranger.vim', { 'on' : 'RangerCurrentDirectory' }
			let g:ranger_map_keys = 0
	endif
endfunction

" Wed Apr 04 2018 10:51: Neither of them seemed to work. Tags file handling is a
" difficult thing. Specially to support in multi OS environments.
" choice - One of ['gen_tags', 'gutentags']
function! s:configure_tag_handler(choice) abort
	if a:choice ==? 'gen_tags'
		Plug 'jsfaint/gen_tags.vim' " Not being suppoprted anymore
			let g:gen_tags#ctags_auto_gen = 1
			let g:gen_tags#gtags_auto_gen = 1
			let g:gen_tags#use_cache_dir = 1
			let g:gen_tags#ctags_prune = 1
			let g:gen_tags#ctags_opts = '--sort=no --append'
	elseif a:choice ==? 'gutentags'
		Plug 'ludovicchabant/vim-gutentags'
			let g:gutentags_modules = []
			if executable('ctags')
				let g:gutentags_modules += ['ctags']
			endif
			if executable('cscope')
				let g:gutentags_modules += ['cscope']
			endif
			" if executable('gtags')
				" let g:gutentags_modules += ['gtags']
			" endif

			let g:gutentags_project_root = ['.svn']
			let g:gutentags_add_default_project_roots = 1

			let g:gutentags_cache_dir = g:std_data_path . '/ctags'

			" if executable('rg')
				" let g:gutentags_file_list_command = 'rg --files'
			" endif

			" Debugging
			let g:gutentags_trace = 1
			" let g:gutentags_fake = 1
			" let g:gutentags_ctags_extra_args = ['--sort=no', '--append']
			let g:lightline.active.left[2] += [ 'tags' ]
			let g:lightline.component_function['tags'] = 'gutentags#statusline'

			augroup MyGutentagsStatusLineRefresher
				autocmd!
				autocmd User GutentagsUpdating call lightline#update()
				autocmd User GutentagsUpdated call lightline#update()
			augroup END

	endif
endfunction
