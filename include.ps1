foreach ($file in (Get-ChildItem -Recurse -Path *.md)) {
    Write-Host "Processing $file"
    $content = Get-Content $file -Raw
    $replacements = @{}
    foreach ($match in (Select-String -Pattern '<!--\s?include (.*?)\s?-->' -Path $file)) {
        $includedPath = ($match.Matches[0].Value -replace '<!--\s?include ','' -replace '\s?-->', '').Trim()
        if (Test-Path $includedPath) {
            $include = Get-Content $includedPath -Raw
            # see if we already have a section we previously replaced
            $existingRegex = "<!--\s?include $includedPath\s?-->[\s\S]*<!-- $includedPath -->"
            $replacement = "<!-- include $includedPath -->`n$include`n<!-- $includedPath -->"
            if ($content -match $existingRegex) {
                $replacements[$existingRegex] = $replacement
            } else {
                $replacements["<!--\s?include $includedPath\s?-->"] = $replacement
            }
        } else {
            Write-Error "Included file $includedPath in $($file.Name) not found" 
        }
    }

    if ($replacements.Count -gt 0) {
        foreach ($replacement in $replacements.GetEnumerator()) {
            write-host "Replacing $($replacement.Key) with $($replacement.Value)"
            $content = $content -replace $replacement.Key, $replacement.Value
        }
        Set-Content $file -Value $content.TrimEnd()
        Write-Host "Updated $($file.Name)"
    }
}
