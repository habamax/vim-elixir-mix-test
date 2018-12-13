if exists("g:loaded_elixir_mix_test") || v:version < 700
	finish
endif
let g:loaded_elixir_mix_test = 1

augroup MIX_TEST
	au!
	au BufRead,BufNewFile *.ex,*.exs call s:define_commands()
	au BufEnter *mix\ test\ output call s:set_project_root()
augroup end

fun! s:define_commands()
	command! -buffer MixTestRun :call elixir_mix_test#run_tests()
endfu

fun! s:set_project_root ()
	if exists('b:mix_project_root')
		exe 'lcd '.b:mix_project_root
	endif
endfu

" put into .vim/after/ftplugin/elixir.vim
" nmap <leader>tt <Plug>(MixTestRun) 
nnoremap <Plug>(MixTestRun) :MixTestRun<CR>
