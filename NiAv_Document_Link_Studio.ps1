Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$script:Docs = @{}
$script:Items = @{}
$script:Closed = @{}
$script:CurrentFolder = $null
$script:SelectedId = $null

function Get-DocumentData([string]$Path) {
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $ids = [regex]::Matches($raw, '\b(?:O-[A-Z0-9-]+|OD-[A-Z0-9-]+|RTM-O[A-Z0-9-]*|D-[A-Z0-9-]+|A-[A-Z0-9-]+|R-[A-Z0-9-]+|WP-[A-Z0-9-]+)\b', 'IgnoreCase') | ForEach-Object { $_.Value.ToUpperInvariant() } | Sort-Object -Unique
    $contexts = @{}
    foreach ($m in [regex]::Matches($raw, '(?is)(?:<tr\b.*?</tr>|<p\b.*?</p>|<li\b.*?</li>)')) {
        $plain = [regex]::Replace($m.Value, '<[^>]+>', ' ')
        $plain = [System.Net.WebUtility]::HtmlDecode(($plain -replace '\s+', ' ')).Trim()
        if ($plain -match '(?i)\b(?:TBC|TBD|open|unresolved|pending|verify|to be decided|to be confirmed|not yet frozen)\b|\[VERIFY\]') {
            foreach ($id in ([regex]::Matches($plain, '\b(?:O-[A-Z0-9-]+|OD-[A-Z0-9-]+|RTM-O[A-Z0-9-]*|D-[A-Z0-9-]+|A-[A-Z0-9-]+|R-[A-Z0-9-]+|WP-[A-Z0-9-]+)\b', 'IgnoreCase') | ForEach-Object { $_.Value.ToUpperInvariant() } | Sort-Object -Unique)) {
                if (-not $contexts.ContainsKey($id)) { $contexts[$id] = $plain }
            }
        }
    }
    return @{ Path = $Path; Name = [IO.Path]::GetFileName($Path); Raw = $raw; Items = $contexts }
}

function Scan-Folder([string]$Folder) {
    $script:Docs = @{}
    $script:Items = @{}
    $script:Closed = @{}
    $statePath = Join-Path $Folder '.niav_linker_closures.json'
    if (Test-Path -LiteralPath $statePath) {
        $stateRaw = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
        # Recover IDs from older malformed state files as well as normal JSON.
        foreach ($match in [regex]::Matches($stateRaw, '(?is)"id"\s*:\s*"([^"]+)"\s*,\s*"status"\s*:\s*"([^"]+)"')) {
            if ($match.Groups[2].Value -in @('Closed','Decided','Verified','Superseded')) {
                $script:Closed[$match.Groups[1].Value.Trim().ToUpperInvariant()] = $match.Groups[2].Value.Trim()
            }
        }
        try {
            foreach ($record in @($stateRaw | ConvertFrom-Json)) {
                if ($record.status -in @('Closed','Decided','Verified','Superseded')) {
                    $script:Closed[$record.id.ToString().ToUpperInvariant()] = $record.status.ToString()
                }
            }
        } catch { }
    }
    foreach ($file in Get-ChildItem -LiteralPath $Folder -Filter '*.html' -File | Sort-Object Name) {
        $doc = Get-DocumentData $file.FullName
        $script:Docs[$doc.Name] = $doc
        foreach ($m in [regex]::Matches($doc.Raw, '(?is)<section id="niav-closure-ledger".*?</section>')) {
            foreach ($row in [regex]::Matches($m.Value, '(?is)<tr>\s*<td><code>([^<]+)</code></td>\s*<td>([^<]+)</td>')) {
                $script:Closed[$row.Groups[1].Value.Trim().ToUpperInvariant()] = $row.Groups[2].Value.Trim()
            }
        }
    }
    foreach ($doc in $script:Docs.Values) {
        foreach ($id in $doc.Items.Keys) {
            if ($script:Closed.ContainsKey($id)) { continue }
            if (-not $script:Items.ContainsKey($id)) { $script:Items[$id] = @{ Id=$id; Context=$doc.Items[$id]; Docs=New-Object System.Collections.Generic.List[string] } }
            $script:Items[$id].Docs.Add($doc.Name)
        }
    }
}

function Html([string]$Value) { [System.Net.WebUtility]::HtmlEncode($Value) }

function Ledger([array]$Rows) {
    $trs = foreach ($r in $Rows) {
        '<tr><td><code>{0}</code></td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>' -f (Html $r.Id),(Html $r.Status),(Html $r.Decision),(Html $r.Evidence),(Html (($r.Docs -join ', '))),(Html $r.Timestamp)
    }
    return "<section id=`"niav-closure-ledger`" class=`"niav-linker-ledger`"><h2>NiAv Cross-Document Closure Ledger</h2><p>This generated ledger records owner decisions and verification closures. Original text and IDs are retained.</p><table><thead><tr><th>ID</th><th>Status</th><th>Resolution / decision</th><th>Evidence / input</th><th>Affected documents</th><th>Recorded</th></tr></thead><tbody>$($trs -join '')</tbody></table></section>"
}

function Apply-Resolution([hashtable]$Resolution) {
    $folder = Split-Path $script:Docs[$Resolution.Docs[0]].Path -Parent
    $backupDir = Join-Path $folder '.niav_linker_backups'
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    $existingRows = @{}
    foreach ($name in $Resolution.Docs) {
        $existingRows[$name] = New-Object System.Collections.Generic.List[object]
        $sourceDoc = $script:Docs[$name]
        foreach ($section in [regex]::Matches($sourceDoc.Raw, '(?is)<section id="niav-closure-ledger".*?</section>')) {
            foreach ($row in [regex]::Matches($section.Value, '(?is)<tr>\s*<td><code>([^<]+)</code></td>\s*<td>([^<]+)</td>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*<td>(.*?)</td>\s*<td>([^<]*)</td>')) {
                $existingRows[$name].Add([pscustomobject]@{
                    Id=[System.Net.WebUtility]::HtmlDecode($row.Groups[1].Value).Trim(); Status=[System.Net.WebUtility]::HtmlDecode($row.Groups[2].Value).Trim(); Decision=[System.Net.WebUtility]::HtmlDecode(([regex]::Replace($row.Groups[3].Value,'<[^>]+>',' '))).Trim(); Evidence=[System.Net.WebUtility]::HtmlDecode(([regex]::Replace($row.Groups[4].Value,'<[^>]+>',' '))).Trim(); Docs=@(); Timestamp=[System.Net.WebUtility]::HtmlDecode($row.Groups[6].Value).Trim()
                })
            }
        }
    }
    $newRow = [pscustomobject]@{ Id=$Resolution.Id; Status=$Resolution.Status; Decision=$Resolution.Decision; Evidence=$Resolution.Evidence; Docs=@($Resolution.Docs); Timestamp=$Resolution.Timestamp }
    foreach ($name in $Resolution.Docs) {
        if (-not $script:Docs.ContainsKey($name)) { continue }
        $doc = $script:Docs[$name]
        $backup = Join-Path $backupDir "$($doc.Name).$stamp.bak.html"
        Copy-Item -LiteralPath $doc.Path -Destination $backup -Force
        $content = $doc.Raw -replace '(?is)\s*<section id="niav-closure-ledger".*?</section>\s*', ''
        $rows = @($existingRows[$name] | Where-Object { $_.Id -ne $Resolution.Id }) + @($newRow)
        $section = Ledger $rows
        if ($content -match '(?i)</body>') { $content = [regex]::Replace($content, '(?i)</body>', "$section</body>", 1) } else { $content += $section }
        Set-Content -LiteralPath $doc.Path -Value $content -Encoding UTF8
        $doc.Raw = $content
    }
    $statePath = Join-Path $folder '.niav_linker_closures.json'
    $state = [ordered]@{}
    if (Test-Path -LiteralPath $statePath) {
        try {
            foreach ($record in @((Get-Content -LiteralPath $statePath -Raw -Encoding UTF8) | ConvertFrom-Json)) {
                if ($record.id) { $state[$record.id.ToString()] = $record }
            }
        } catch { }
    }
    $state[$Resolution.Id] = [pscustomobject]@{ id=$Resolution.Id; status=$Resolution.Status; decision=$Resolution.Decision; evidence=$Resolution.Evidence; timestamp=$Resolution.Timestamp; documents=@($Resolution.Docs) }
    $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8
    if ($Resolution.Status -in @('Closed','Decided','Verified','Superseded')) {
        $script:Closed[$Resolution.Id] = $Resolution.Status
        [void]$script:Items.Remove($Resolution.Id)
    }
}

$form = New-Object Windows.Forms.Form
$form.Text = 'NiAv Document Link Studio v0.3 - Live refresh'
$form.Size = New-Object Drawing.Size(1160,760)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object Drawing.Font('Segoe UI',10)

$top = New-Object Windows.Forms.Panel; $top.Dock='Top'; $top.Height=58; $form.Controls.Add($top)
$pick = New-Object Windows.Forms.Button; $pick.Text='Select document folder'; $pick.Location=New-Object Drawing.Point(12,13); $pick.Size=New-Object Drawing.Size(180,32); $top.Controls.Add($pick)
$refreshButton = New-Object Windows.Forms.Button; $refreshButton.Text='Refresh unresolved IDs'; $refreshButton.Location=New-Object Drawing.Point(202,13); $refreshButton.Size=New-Object Drawing.Size(170,32); $top.Controls.Add($refreshButton)
$folderLabel = New-Object Windows.Forms.Label; $folderLabel.Text='No folder selected'; $folderLabel.Location=New-Object Drawing.Point(385,19); $folderLabel.AutoSize=$true; $top.Controls.Add($folderLabel)
$statusLabel = New-Object Windows.Forms.Label; $statusLabel.Text='Select the folder containing the NiAv HTML files. Live refresh is enabled.'; $statusLabel.Location=New-Object Drawing.Point(12,65); $statusLabel.AutoSize=$true; $form.Controls.Add($statusLabel)

$left = New-Object Windows.Forms.Panel; $left.Location=New-Object Drawing.Point(12,98); $left.Size=New-Object Drawing.Size(350,600); $left.Anchor='Top,Bottom,Left'; $form.Controls.Add($left)
$search = New-Object Windows.Forms.TextBox; $search.Location=New-Object Drawing.Point(0,0); $search.Width=340; $left.Controls.Add($search)
$list = New-Object Windows.Forms.ListBox; $list.Location=New-Object Drawing.Point(0,35); $list.Size=New-Object Drawing.Size(340,555); $list.Anchor='Top,Bottom,Left,Right'; $left.Controls.Add($list)

$right = New-Object Windows.Forms.Panel; $right.Location=New-Object Drawing.Point(380,98); $right.Size=New-Object Drawing.Size(750,600); $right.Anchor='Top,Bottom,Left,Right'; $form.Controls.Add($right)
$heading = New-Object Windows.Forms.Label; $heading.Text='Select an unresolved item'; $heading.Font=New-Object Drawing.Font('Segoe UI',14,[Drawing.FontStyle]::Bold); $heading.Location=New-Object Drawing.Point(0,0); $heading.AutoSize=$true; $right.Controls.Add($heading)
$linked = New-Object Windows.Forms.Label; $linked.Text=''; $linked.Location=New-Object Drawing.Point(0,38); $linked.AutoSize=$true; $right.Controls.Add($linked)
$context = New-Object Windows.Forms.TextBox; $context.Multiline=$true; $context.ReadOnly=$true; $context.ScrollBars='Vertical'; $context.Location=New-Object Drawing.Point(0,70); $context.Size=New-Object Drawing.Size(730,110); $right.Controls.Add($context)
$right.Controls.Add((New-Object Windows.Forms.Label -Property @{Text='Status';Location=(New-Object Drawing.Point(0,195));AutoSize=$true}))
$status = New-Object Windows.Forms.ComboBox; $status.Items.AddRange(@('Closed','Decided','Verified','Superseded','Deferred')); $status.SelectedIndex=0; $status.Location=New-Object Drawing.Point(0,218); $status.Width=250; $right.Controls.Add($status)
$right.Controls.Add((New-Object Windows.Forms.Label -Property @{Text='Resolution / decision';Location=(New-Object Drawing.Point(0,258));AutoSize=$true}))
$decision = New-Object Windows.Forms.TextBox; $decision.Multiline=$true; $decision.ScrollBars='Vertical'; $decision.Location=New-Object Drawing.Point(0,281); $decision.Size=New-Object Drawing.Size(730,90); $right.Controls.Add($decision)
$right.Controls.Add((New-Object Windows.Forms.Label -Property @{Text='Evidence / input';Location=(New-Object Drawing.Point(0,387));AutoSize=$true}))
$evidence = New-Object Windows.Forms.TextBox; $evidence.Multiline=$true; $evidence.ScrollBars='Vertical'; $evidence.Location=New-Object Drawing.Point(0,410); $evidence.Size=New-Object Drawing.Size(730,70); $right.Controls.Add($evidence)
$apply = New-Object Windows.Forms.Button; $apply.Text='Apply closure to all linked documents'; $apply.Location=New-Object Drawing.Point(0,510); $apply.Size=New-Object Drawing.Size(285,38); $right.Controls.Add($apply)
$help = New-Object Windows.Forms.Label; $help.Text='Backups are created in .niav_linker_backups beside the documents.'; $help.Location=New-Object Drawing.Point(0,560); $help.AutoSize=$true; $right.Controls.Add($help)

$refresh = { $list.Items.Clear(); $q=$search.Text.ToLowerInvariant(); foreach ($id in ($script:Items.Keys | Sort-Object)) { if ([string]::IsNullOrWhiteSpace($q) -or $id.ToLowerInvariant().Contains($q) -or $script:Items[$id].Context.ToLowerInvariant().Contains($q)) { [void]$list.Items.Add($id) } }; $references=0; foreach ($entry in $script:Items.Values) { $references += $entry.Docs.Count }; $statusLabel.Text="$($script:Items.Count) unique unresolved IDs / $references unresolved document references across $($script:Docs.Count) documents." }
$reload = { if ([string]::IsNullOrWhiteSpace($script:CurrentFolder)) { [Windows.Forms.MessageBox]::Show('Select the document folder first.','NiAv'); return }; try { Scan-Folder $script:CurrentFolder; & $refresh; [Windows.Forms.MessageBox]::Show("List refreshed from: $script:CurrentFolder`n$($script:Items.Count) unique unresolved IDs remain.",'NiAv refresh complete') } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'NiAv refresh failed') } }
$pick.Add_Click({ $dialog=New-Object Windows.Forms.FolderBrowserDialog; $dialog.Description='Select the folder containing the NiAv HTML documents'; if ($dialog.ShowDialog() -eq 'OK') { $script:CurrentFolder=$dialog.SelectedPath; Scan-Folder $script:CurrentFolder; $folderLabel.Text=$script:CurrentFolder; & $refresh } })
$refreshButton.Add_Click($reload)
$search.Add_TextChanged($refresh)
$list.Add_SelectedIndexChanged({ if ($null -eq $list.SelectedItem) { return }; $script:SelectedId=[string]$list.SelectedItem; $item=$script:Items[$script:SelectedId]; $heading.Text=$script:SelectedId; $linked.Text='Linked documents: '+($item.Docs -join ', '); $context.Text=$item.Context; $decision.Clear(); $evidence.Clear(); $status.SelectedIndex=0 })
$apply.Add_Click({ if (-not $script:SelectedId) { [Windows.Forms.MessageBox]::Show('Select an unresolved item first.','NiAv'); return }; if ([string]::IsNullOrWhiteSpace($decision.Text)) { [Windows.Forms.MessageBox]::Show('Enter a resolution or decision first.','NiAv'); return }; $r=@{Id=$script:SelectedId;Status=$status.Text;Decision=$decision.Text.Trim();Evidence=$evidence.Text.Trim();Docs=$script:Items[$script:SelectedId].Docs;Timestamp=(Get-Date).ToString('s')}; try { Apply-Resolution $r; [void]$list.Items.Remove($r.Id); Scan-Folder (Split-Path $script:Docs[$r.Docs[0]].Path -Parent); & $refresh; [Windows.Forms.MessageBox]::Show("Updated $($r.Docs.Count) linked document(s).`n$($script:Items.Count) unique unresolved IDs remain.",'NiAv closure applied') } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message,'NiAv update failed') } })

[void]$form.ShowDialog()
