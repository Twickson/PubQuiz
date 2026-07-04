<#
.SYNOPSIS
  Laedt neue Trivia-Fragen von opentdb.com, uebersetzt sie mit Claude Haiku 4.5
  ins Deutsche und haengt sie an data/questions.json an.

.PARAMETER Amount
  Anzahl NEUER Fragen, die in diesem Lauf hinzugefuegt werden sollen.
  Steuert direkt die Anzahl der Claude-API-Aufrufe / Tokens pro Lauf.

.EXAMPLE
  $env:ANTHROPIC_API_KEY = "sk-ant-..."
  .\scripts\build-question-db.ps1 -Amount 20
#>
param(
  [int]$Amount = 100
)

$ErrorActionPreference = 'Stop'

if (-not $env:ANTHROPIC_API_KEY) {
  Write-Error "ANTHROPIC_API_KEY ist nicht gesetzt. Setze ihn zuerst, z.B.:`n  `$env:ANTHROPIC_API_KEY = 'sk-ant-...'"
  exit 1
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$dbDir = Join-Path $repoRoot 'data'
$dbPath = Join-Path $dbDir 'questions.json'

if (-not (Test-Path $dbDir)) { New-Item -ItemType Directory -Path $dbDir | Out-Null }

if (Test-Path $dbPath) {
  $db = Get-Content -Path $dbPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
  $db = [PSCustomObject]@{ version = 1; questions = @() }
}

$questionsList = New-Object System.Collections.Generic.List[object]
foreach ($q in $db.questions) { $questionsList.Add($q) }

$existingKeys = New-Object System.Collections.Generic.HashSet[string]
foreach ($q in $questionsList) {
  $existingKeys.Add($q.en.q.Trim().ToLowerInvariant()) | Out-Null
}

$categoryMap = @{
  'General Knowledge'                     = 9
  'Entertainment: Books'                  = 10
  'Entertainment: Film'                   = 11
  'Entertainment: Music'                  = 12
  'Entertainment: Musicals & Theatres'    = 13
  'Entertainment: Television'             = 14
  'Entertainment: Video Games'            = 15
  'Entertainment: Board Games'            = 16
  'Science & Nature'                      = 17
  'Science: Computers'                    = 18
  'Science: Mathematics'                  = 19
  'Mythology'                             = 20
  'Sports'                                = 21
  'Geography'                             = 22
  'History'                               = 23
  'Politics'                              = 24
  'Art'                                   = 25
  'Celebrities'                           = 26
  'Animals'                               = 27
  'Vehicles'                              = 28
  'Entertainment: Comics'                 = 29
  'Science: Gadgets'                      = 30
  'Entertainment: Japanese Anime & Manga' = 31
  'Entertainment: Cartoon & Animations'   = 32
}

function Decode-Base64Utf8 {
  param([string]$b64)
  if ([string]::IsNullOrEmpty($b64)) { return '' }
  return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
}

Write-Host "Suche $Amount neue Fragen aus allen Kategorien..."

$newRaw = New-Object System.Collections.Generic.List[object]
$attempts = 0
while ($newRaw.Count -lt $Amount -and $attempts -lt 15) {
  $attempts++
  $remaining = $Amount - $newRaw.Count
  $fetchAmount = [Math]::Min(50, [Math]::Max(10, $remaining * 2))
  $uri = "https://opentdb.com/api.php?amount=$fetchAmount&type=multiple&encode=base64"

  try {
    $resp = Invoke-RestMethod -Uri $uri -Method Get
  } catch {
    Write-Warning "opentdb-Anfrage fehlgeschlagen: $_"
    Start-Sleep -Seconds 5
    continue
  }

  if ($resp.response_code -ne 0) {
    Write-Warning "opentdb response_code $($resp.response_code) - warte 5s und versuche erneut..."
    Start-Sleep -Seconds 5
    continue
  }

  foreach ($r in $resp.results) {
    $qText = Decode-Base64Utf8 $r.question
    $key = $qText.Trim().ToLowerInvariant()
    if ($existingKeys.Contains($key)) { continue }
    $existingKeys.Add($key) | Out-Null

    $catName = Decode-Base64Utf8 $r.category
    $catId = $categoryMap[$catName]
    if (-not $catId) {
      Write-Warning "Unbekannte Kategorie '$catName' - Frage wird uebersprungen."
      continue
    }

    $newRaw.Add([PSCustomObject]@{
      category   = $catId
      difficulty = Decode-Base64Utf8 $r.difficulty
      en         = [PSCustomObject]@{
        q         = $qText
        correct   = Decode-Base64Utf8 $r.correct_answer
        incorrect = @($r.incorrect_answers | ForEach-Object { Decode-Base64Utf8 $_ })
      }
    })

    if ($newRaw.Count -ge $Amount) { break }
  }

  if ($newRaw.Count -lt $Amount) { Start-Sleep -Seconds 5 }
}

if ($newRaw.Count -eq 0) {
  Write-Host "Keine neuen Fragen gefunden. Datenbank bleibt unveraendert."
  exit 0
}

if ($newRaw.Count -gt $Amount) {
  $newRaw = $newRaw.GetRange(0, $Amount)
}

Write-Host "$($newRaw.Count) neue Fragen gefunden. Uebersetze via Claude Haiku 4.5..."

$flatTexts = New-Object System.Collections.Generic.List[string]
foreach ($q in $newRaw) {
  $flatTexts.Add($q.en.q)
  $flatTexts.Add($q.en.correct)
  foreach ($inc in $q.en.incorrect) { $flatTexts.Add($inc) }
}

$inputJson = $flatTexts | ConvertTo-Json -Depth 5
$prompt = @"
Uebersetze die folgenden Trivia-Quizfragen und Antworten ins Deutsche. Erhalte die Bedeutung exakt und verwende natuerliche, im Pub-Quiz uebliche Formulierungen. Gib ausschliesslich ein JSON-Objekt im Format {"translations": ["...", "...", ...]} zurueck, mit genau so vielen Eintraegen wie die Eingabe, in identischer Reihenfolge. Keine Erklaerungen, kein Markdown, nur das JSON-Objekt.

Eingabe:
$inputJson
"@

$requestBody = @{
  model      = 'claude-haiku-4-5'
  max_tokens = 8192
  messages   = @(@{ role = 'user'; content = $prompt })
} | ConvertTo-Json -Depth 10

$httpClient = New-Object System.Net.Http.HttpClient
$httpClient.DefaultRequestHeaders.Add('x-api-key', $env:ANTHROPIC_API_KEY)
$httpClient.DefaultRequestHeaders.Add('anthropic-version', '2023-06-01')
$content = New-Object System.Net.Http.StringContent($requestBody, [System.Text.Encoding]::UTF8, 'application/json')

try {
  $response = $httpClient.PostAsync('https://api.anthropic.com/v1/messages', $content).GetAwaiter().GetResult()
  $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
  $responseText = [System.Text.Encoding]::UTF8.GetString($bytes)
} finally {
  $httpClient.Dispose()
}

if (-not $response.IsSuccessStatusCode) {
  Write-Error "Anthropic API HTTP $($response.StatusCode): $responseText"
  exit 1
}

$responseJson = $responseText | ConvertFrom-Json
$rawText = $responseJson.content[0].text
$rawText = $rawText -replace '^```json\s*', '' -replace '^```\s*', '' -replace '```\s*$', ''
$parsed = $rawText | ConvertFrom-Json
$translations = @($parsed.translations)

if ($translations.Count -ne $flatTexts.Count) {
  Write-Error "Uebersetzung unvollstaendig oder fehlerhaft (erwartet $($flatTexts.Count), erhalten $($translations.Count)). Keine Aenderungen gespeichert."
  exit 1
}

$idx = 0
foreach ($q in $newRaw) {
  $deQ = $translations[$idx]; $idx++
  $deCorrect = $translations[$idx]; $idx++
  $deIncorrect = @()
  foreach ($inc in $q.en.incorrect) { $deIncorrect += $translations[$idx]; $idx++ }

  $entry = [PSCustomObject]@{
    category   = $q.category
    difficulty = $q.difficulty
    en         = $q.en
    de         = [PSCustomObject]@{ q = $deQ; correct = $deCorrect; incorrect = $deIncorrect }
  }
  $questionsList.Add($entry)
}

$db.questions = $questionsList.ToArray()
$outJson = $db | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($dbPath, $outJson, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "$($newRaw.Count) Fragen uebersetzt und gespeichert."
Write-Host "Datenbank enthaelt jetzt $($questionsList.Count) Fragen insgesamt."
Write-Host ""
Write-Host "Nicht vergessen: git add data/questions.json, committen und pushen, damit die Website die neuen Fragen bekommt."
