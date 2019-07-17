fun! s:mix_test(test_buf)
	if exists('*job_start')
		if has('win32')
			let cmd = &shell . ' ' . &shellcmdflag . ' mix test'
		else
			let cmd = split(&shell) + split(&shellcmdflag) + ['mix test']
		endif
		let job = job_start(cmd, {
					\ 'out_io': 'buffer',
					\ 'out_name': a:test_buf
					\ })
	else
		silent %!mix test
	endif
endfu

fun! elixir_mix_test#run_tests()
	let project_root = s:project_root()
	let current_buf = bufwinnr("%")

	"" I don't think I like preview window...
	" let test_buf = fnamemodify(project_root, ':t')." -- mix test output"
	" exe 'pedit '.test_buf
	" let bufnr = bufwinnr('^'.test_buf.'$')
	" exe bufnr."wincmd w"
	" setl buftype=nofile
	" setl bufhidden=delete
	" setl noswapfile
	" nnoremap <buffer> q <C-w>c

	let test_buf = fnamemodify(project_root, ':t')." -- mix test output"
	let bufnr = bufwinnr('^'.test_buf.'$')
	if bufnr == -1
		exe 'new '. test_buf
		setl buftype=nofile
		setl bufhidden=hide
		setl noswapfile

		" delete previous contents
		%d_

		" to be able to `gf` filenames like (mostly for Windows):
		"        lib/day5.ex:15: Day5 (module)
		setl isfname-=:

		nnoremap <buffer> q <C-w>c
		nnoremap <buffer> <CR> gF
		command! -buffer MixTestNext :call <sid>next_test('down')
		command! -buffer MixTestPrev :call <sid>next_test('up')
		nnoremap <buffer> <C-n> :MixTestNext<CR>
		nnoremap <buffer> <C-p> :MixTestPrev<CR>

		let b:mix_project_root = project_root

		if g:elixir_mix_test_position == "top"
			exe "wincmd K"
		elseif g:elixir_mix_test_position == "bottom"
			exe "wincmd J"
		elseif g:elixir_mix_test_position == "left"
			exe "wincmd H"
		elseif g:elixir_mix_test_position == "right"
			exe "wincmd L"
		endif
	else
		exe bufnr."wincmd w"
		" delete previous contents
		%d_
	endif

	" colorize it
	syn clear

	syntax include @ElixirSourceHighlight syntax/elixir.vim

	" Test heading
	syntax cluster MixTestTitleParts contains=MixTestTitleFront,MixTestTitleTail
	syntax match MixTestTitleFront /\v^\s+\d+\)\s((test|doctest)\s)?/ contains=MixTestTitleNum,MixTestTitleType containedin=@MixTestTitleParts
	syntax match MixTestTitle /\v^\s+\d+\)\s+.*$/ contains=@MixTestTitleParts
	syntax match MixTestTitleNum /\v\s+\d+\)\s*/ contained containedin=MixTestTitleFront
	syntax match MixTestTitleType /\v(test|doctest)/ contained containedin=MixTestTitleFront
	syntax match MixTestTitleTail /\v\s+\([^()]{-}\)$/ contained containedin=MixTestTitle
	syntax match MixTestTitleTail /\v\(\d+\)\s\([^()]{-}\)$/ contained containedin=MixTestTitle
	hi link MixTestTitle Title
	hi link MixTestTitleNum Statement
	hi link MixTestTitleType Statement
	hi link MixTestTitleTail Comment

	syntax region MixTestElixirCode matchgroup=MixTestAttr start="^\s*code:\s*" end="^\ze\s*left:" contains=@ElixirSourceHighlight
	syntax region MixTestElixirCode matchgroup=MixTestAttr start="^\s*left:\s*" end="^\ze\s*right:" contains=@ElixirSourceHighlight
	syntax region MixTestElixirCode matchgroup=MixTestAttr start="^\s*right:\s*" end="^\ze\s*stacktrace:" contains=@ElixirSourceHighlight
	syntax match MixTestAttr /\v^\s*\zs(code|left|right|stacktrace):/
	syntax match MixTestDoctestFailed /\v^\s*\zsDoctest failed/
	syntax match MixTestTestFailed /\v^\s*\zsAssertion with .* failed/
	syntax match MixTestFinished /\v^Finished in \d+\.\d+ seconds$/
	syntax match MixTestResults /\v^\d+ doctest%[s], \d+ test%[s], \d+ failure%[s]$/
	syntax match MixTestResults /\v^\d+ doctest%[s], \d+ failure%[s]$/
	syntax match MixTestResults /\v^\d+ test%[s], \d+ failure%[s]$/
	syntax match MixTestRandomized /\v^Randomized with seed \d+$/
	syntax match MixTestComment /\v^# .*$/
	syntax match MixTestCompilationErrorMsgTitle /\v^\=\=\s.+\s\=\=$/
	syntax match MixTestCompilationErrorMsgSubTitle /\v^\*\*\s\(.{-}\)/
	hi link MixTestAttr Special
	hi link MixTestDoctestFailed ErrorMsg
	hi link MixTestTestFailed ErrorMsg
	hi link MixTestResults Title
	hi link MixTestFinished Comment
	hi link MixTestRandomized Comment
	hi link MixTestComment Comment
	hi link MixTestCompilationErrorMsgTitle Title
	hi link MixTestCompilationErrorMsgSubTitle ErrorMsg

	" make it async
	exe 'lcd '. project_root

	call s:mix_test(test_buf)

	call s:add_help()

	" scroll to bottom
	normal G

	" get back to the buffer we started tests from
	exe current_buf."wincmd w"
endfu

fun! s:next_test(direction)
	if a:direction == 'down'
		let flags = 'W'
	else
		let flags = 'Wb'
	endif
	call search('\v^\s+\d+\)\s+(test|doctest)', flags)
endfu

fun! s:add_help()
	call append(0, "# ----")
	call append(1, "# <C-n> - jump to next test")
	call append(2, "# <C-p> - jump to previous test")
	call append(3, "# <CR>  - open file under cursor at specified line `lib/hello.ex:5`")
	call append(4, "# q     - close this window")
	call append(5, "# ----")
endfu

fun! s:project_root()
	return fnamemodify(findfile("mix.exs", expand("%:p:h").";"), ":p:h")
endfu

