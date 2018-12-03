#'[O]pen [C]lipboard [D]iff [x]Checkout [A]dd [R]eset [ ]Clear [U]pdate'

function ask($options) {
  $sel = 0
  $fg = $host.UI.RawUI.ForegroundColor
  $bg = $host.UI.RawUI.BackgroundColor
  $yo = $host.UI.RawUI.CursorPosition

  for (;;) {
    $host.UI.RawUI.CursorPosition = @{ x = $yo.x; y = $yo.y }
    for ($i = 0; $i -lt $options.length; ++$i) {
      if ($i -eq $sel) { write-host $options[$i] -foreground $bg -background $fg -nonewline }
      else { write-host $options[$i] -nonewline }
      write-host " " -nonewline
    }

    $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
    $vkeycode = $press.virtualkeycode
  
    if ($vkeycode -eq 37) { $sel-- }
    if ($vkeycode -eq 39) { $sel++ }
    if ($sel -lt 0) { $sel = 0 }
    if ($sel -ge $options.length) { $sel = $options.length-1 }
    if ($vkeycode -eq 13) {
      $host.UI.RawUI.CursorPosition = @{ x = $yo.x; y = $yo.y }
      for ($i = 0; $i -lt $options.length; ++$i) {
        $txt = " "*($options[$i].length+1)
        write-host $txt -nonewline
      }
      $host.UI.RawUI.CursorPosition = @{ x = $yo.x; y = $yo.y }
      return $sel
    }
  }
}

function gitx-branch {
	$branches = [System.Array]( git branch --no-color )
	$script:num = $branches.length
	$script:items = New-Object String[] $script:num
	for ($i = 0; $i -lt $script:num; ++$i) {
		$script:items[$i] = $branches[$i].substring(2)
		if ($branches[$i].substring(0,1) -eq '*') {
			$script:index = $i
		}
	}

	for ($i = 0; $i -lt $script:num; ++$i) {
		if ( $script:index -eq $i ) {
			write-host $branches[$i] -BackgroundColor $fgc -ForegroundColor $bgc
		}
		else {
			write-host $branches[$i] -BackgroundColor $bgc -ForegroundColor $fgc
		}
	}

	$script:endY = [console]::CursorTop
	$script:beginY = $script:endY - $script:num

	for (;;) {
		[console]::setcursorposition(0, $script:beginY + $script:index)
		write-host $branches[$script:index] -BackgroundColor $fgc -ForegroundColor $bgc -NoNewline

		$key = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
		$vkeycode = $key.virtualkeycode
		$old = $script:index

		if ($vkeycode -eq 27 -or $vkeycode -eq [int32][char]'Q') {
			[console]::setcursorposition(0, $script:endY)
			break done;
		}
		elseif ($vkeycode -eq 38) {
			if ($script:index -gt 0) {
				$script:index--
			}
		}
		elseif ($vkeycode -eq 40) {
			if ($script:index -lt $script:num - 1) {
				$script:index++
			}
		}
		elseif ($vkeycode -eq 33) {
			if ($script:index -gt 5) {
				$script:index -= 5
			} else {
				$script:index = 0
			}
		}
		elseif ($vkeycode -eq 34) {
			if ($script:index -lt $script:num - 5 - 1 ) {
				$script:index += 5
			} else {
				$script:index = $script:num - 1
			}
		}
		elseif ($vkeycode -eq 13 ) {
			[console]::setcursorposition(0, $script:beginY + $script:index)
			write-host $branches[$script:index] -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
			[console]::setcursorposition(0, $endY)
			git checkout $script:items[$script:index]
			return
		}

		if ($script:index -ne $old) {
			[console]::setcursorposition(0, $script:beginY + $old)
			write-host $branches[$old] -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
		}
	}
}

try {
	$dte = [System.Runtime.InteropServices.Marshal]::GetActiveObject("VisualStudio.DTE.15.0")
} catch {
	$dte = 0
}
$bgc = [console]::BackgroundColor
$fgc = [console]::ForegroundColor

if ($args[0] -eq 'branch') {
	gitx-branch $args
	return
}

$groups = @(
  @{key="x"; cmd="git checkout"; },
  @{key="a"; cmd="git add";      },
  @{key="r"; cmd="git reset -q"; }
)

function read-git-status {
	$status = [System.Array](git status --porcelain)
	$script:num = $status.length
	$script:items = New-Object Hashtable[] $script:num
	for ($i = 0; $i -lt $script:num; ++$i) {
		$itemstat = $status[$i].substring(0, 2)
		$filename = $status[$i].substring(3)
		$action = " "
		$script:items[$i] = @{action=" "; status=$itemstat; file=$filename}
	}
	$script:branch = (git status --branch --porcelain -)
}

function update-git-status($index) {
	$status = (git status --porcelain $script:items[$index].file)
	$itemstat = $status.substring(0, 2)
	$filename = $status.substring(3)
	$script:items[$index] = @{action=" "; status=$itemstat; file=$filename}
}

function item-text($index) {
	if ($index -ge $script:num) {
		return ""
	}
	$item = $script:items[$index]
	return $item.action + " [" + $item.status + "] " + $item.file
}

function print-list {
	write-host $script:branch
	for ($i = 0; $i -lt $script:num; ++$i) {
		write-host (item-text $i)
	}
}

function clear-list {
	write-host (' '*$script:branch.length)
	for ($i = 0; $i -lt $script:num; ++$i) {
		write-host (' '*(item-text $i).length)
	}
}

function reload {
	read-git-status
	print-list
	$script:endY = [console]::CursorTop
	$script:index = $script:num - 1
	$script:beginY = $script:endY - $script:num
}

reload

for (;;) {
	[console]::setcursorposition(0, $script:beginY + $script:index)
	write-host ( item-text $script:index ) -BackgroundColor $fgc -ForegroundColor $bgc -NoNewline

	$key = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
	$vkeycode = $key.virtualkeycode
	$old = $script:index

	if ($vkeycode -eq 27 -or $vkeycode -eq [int32][char]'Q') {
		[console]::setcursorposition(0, $script:beginY + $old)
		write-host (item-text $old) -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
		[console]::setcursorposition(0, $endY)
		break done;
	}
	elseif ($vkeycode -eq 38) {
		if ($script:index -gt 0) {
			$script:index--
		}
	}
	elseif ($vkeycode -eq 40) {
		if ($script:index -lt $script:num - 1) {
			$script:index++
		}
	}
	elseif ($vkeycode -eq 33) {
		if ($script:index -gt 5) {
			$script:index -= 5
		} else {
			$script:index = 0
		}
	}
	elseif ($vkeycode -eq 34) {
		if ($script:index -lt $script:num - 5 - 1 ) {
			$script:index += 5
		} else {
			$script:index = $script:num - 1
		}
	}
	elseif ($groups.key.contains([string]$key.Character)) {
		if ($script:items[$script:index].action -eq $key.Character) {
			$script:items[$script:index].action = ' '
		}
		else {
			$script:items[$script:index].action = [string]$key.Character
		}
		if ($script:index -lt $script:num - 1) {
			$script:index++
		}
	}
	elseif ($vkeycode -eq ([int32][char]' ')) {
		$script:items[$script:index].action = ' '
	}
	elseif ($vkeycode -eq ([int32][char]'O')) {
		if ( $dte -ne 0 ) {
			$file = Split-Path $script:items[$script:index].file -leaf
			### open file
		}
	}
	elseif ($vkeycode -eq ([int32][char]'D')) {
		git difftool $script:items[$script:index].file
	}
	elseif ($vkeycode -eq ([int32][char]'C')) {
		$script:items[$script:index].file | clip
	}
	elseif ($vkeycode -eq ([int32][char]'U')) {
		[console]::setcursorposition(0, $script:beginY - 1)
		clear-list
		[console]::setcursorposition(0, $script:beginY - 1)
		reload
	}
	elseif ($vkeycode -eq 13 ) {
		[console]::setcursorposition(0, $endY)
		for ($g = 0; $g -lt $groups.length; ++$g) {
			$list = @()
			$script:indexes = @()
			for ($i = 0; $i -lt $script:num; ++$i) {
				if ($script:items[$i].action -eq $groups[$g].key) {
					$list += $script:items[$i].file
					$script:indexes += $i
				}
			}
			if ($list.length -ne 0) {
				$cmd = $groups[$g].cmd + " " + $list
				Invoke-Expression $cmd
#				write-host $cmd
#				if (ask @("Cancel", "Run") -eq 1 ) {
#					Invoke-Expression $cmd
#					for ($i = 0; $i -lt $indexes.length; ++$i) {
#						update-git-status $indexes[$i]
#						[console]::setcursorposition(0,$script:beginY+$indexes[$i])
#						write-host ( item-text $indexes[$i] ) -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
#					}
#				}
			}
		}

		[console]::setcursorposition(0, $script:beginY - 1)
		clear-list
		[console]::setcursorposition(0, $script:beginY - 1)
		reload
	}

	if ($script:index -ne $old) {
		[console]::setcursorposition(0, $script:beginY + $old)
		write-host (item-text $old) -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
	}
}

:done
