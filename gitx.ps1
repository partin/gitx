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

$bgc = [console]::BackgroundColor
$fgc = [console]::ForegroundColor

$script:beginY = [console]::CursorTop

$groups = @(
  @{key="c"; cmd="git commit"; },
  @{key="x"; cmd="git checkout"; },
  @{key="a"; cmd="git add";    },
  @{key="r"; cmd="git reset -q";  }
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

function reload {
	read-git-status
	#[console]::setcursorposition(0,$beginY)
	print-list
	$script:endY = [console]::CursorTop
}

reload

$index = $script:num - 1
$saveY = $script:endY - $script:num

for (;;) {
	[console]::setcursorposition(0, $saveY + $index) 
	write-host ( item-text $index ) -BackgroundColor $fgc -ForegroundColor $bgc -NoNewline

	$key = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
	$vkeycode = $key.virtualkeycode
	$old = $index

	if ($vkeycode -eq 27 -or $vkeycode -eq [int32][char]'Q') {
		[console]::setcursorposition(0, $endY)
		break done;
	}
	elseif ($vkeycode -eq 38) {
		if ($index -gt 0) {
			$index--
		}
	}
	elseif ($vkeycode -eq 40) {
		if ($index -lt $num - 1) {
			$index++
		}
	}
	elseif ($vkeycode -eq 33) {
		if ($index -gt 15) {
			$index -= 15
		} else {
			$index = 0
		}
	}
	elseif ($vkeycode -eq 34) {
		if ($index -lt $num - 15 - 1 ) {
			$index += 15
		} else {
			$index = $num - 1
		}
	}
	elseif ($groups.key.contains([string]$key.Character)) {
		if ($script:items[$index].action -eq $key.Character) {
			$script:items[$index].action = ' '
		}
		else {
			$script:items[$index].action = [string]$key.Character
		}
		if ($index -lt $num - 1) {
			$index++
		}		
	}
	elseif ($vkeycode -eq ([int32][char]'D')) {
		git difftool $script:items[$index].file
	}
	elseif ($vkeycode -eq 13 ) {
		[console]::setcursorposition(0, $endY)
		for ($g = 0; $g -lt $groups.length; ++$g) {
			$list = @()
			$indexes = @()
			for ($i = 0; $i -lt $script:num; ++$i) {
				if ($script:items[$i].action -eq $groups[$g].key) {
					$list += $script:items[$i].file
					$indexes += $i
				}
			}
			if ($list.length -ne 0) {
				$cmd = $groups[$g].cmd + " " + $list
#				write-host $cmd
#				if (ask @("Cancel", "Run") -eq 1 ) {
					Invoke-Expression $cmd
					for ($i = 0; $i -lt $indexes.length; ++$i) {
						update-git-status $indexes[$i]
						[console]::setcursorposition(0,$saveY+$indexes[$i])
						write-host ( item-text $indexes[$i] ) -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
					}
#				}
			}
		}
	}

	if ($index -ne $old) {
		[console]::setcursorposition(0, $saveY + $old)
		write-host (item-text $old) -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
	}
}

:done
