$bgc = [console]::BackgroundColor
$fgc = [console]::ForegroundColor

$script:beginY = [console]::CursorTop

function read-git-status {
	$script:branch = ( git status --branch --porcelain - )
	$script:status = [System.Array]( git status --porcelain )
	$script:num = $script:status.length
	$script:files = New-Object String[] $script:num
	for ( $i = 0; $i -lt $script:num; ++$i ) {
		$script:files[$i] = $script:status[$i].substring(3)
	}
}

function print-list {
	write-host $script:branch
	for ( $i = 0; $i -lt $script:num; ++$i ) {
		write-host $script:status[$i]
	}
}

function reload {
	read-git-status
	[console]::setcursorposition(0,$beginY)
	print-list
	$script:endY = [console]::CursorTop
}

reload

$index = $script:num

$saveY = $script:endY - $script:num

for ( ;; ) {
	$key = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
	$vkeycode = $key.virtualkeycode
	$old = $index

	[console]::setcursorposition(0,$saveY+$index) 
	write-host $status[$index] -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline

	if ( $vkeycode -eq 27 -or $vkeycode -eq [int32][char]'Q' ) {
		[console]::setcursorposition(0,$endY) 
		break done;
	}
	elseif ( $vkeycode -eq 38 ) {
		if ($index -gt 0 ) {
			$index--
		}
	}
	elseif ( $vkeycode -eq 40 ) {
		if ($index -lt $num ) {
			$index++
		}
	}
	elseif ( $vkeycode -eq ([int32][char]'A') ) {
		git add $files[$index]
		$script:status[$index] = [System.Array]( git status --porcelain $files[$index] )
	}
	elseif ( $vkeycode -eq ([int32][char]'R') ) {
		git reset -q $files[$index]
		$script:status[$index] = [System.Array]( git status --porcelain $files[$index] )
	}
	elseif ( $vkeycode -eq ([int32][char]'D') ) {
		git difftool $files[$index]
	}

	[console]::setcursorposition(0,$saveY+$index) 
	write-host $status[$index] -BackgroundColor $fgc -ForegroundColor $bgc -NoNewline
}
