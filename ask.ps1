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

# Write-Host "Test: "  -nonewline
# ask(@("Yes", "No", "Cancel"))
