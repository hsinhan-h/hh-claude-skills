<#
.SYNOPSIS
    Generates a "GitHub issue test report" Word (.docx) file.

.DESCRIPTION
    Builds a .docx by hand-assembling raw OOXML (no dependency on python-docx,
    pandoc, or any other external tool). Table columns use a fixed layout with
    explicit widths so long text (e.g. URLs) never breaks the page margins.

    All visible labels (headings, column titles, "Date"/"Tester" labels, etc.)
    are parameters with English defaults. Pass localized strings to match
    whatever language the calling conversation is in — the script itself does
    not decide the language, it only assembles the document.

.PARAMETER Items
    Array of test item strings. Use this or -ItemsJson, not both.

.PARAMETER ItemsJson
    Path to a JSON file with the test items. Either a plain string array
    ["item 1","item 2"] or an object array [{"text":"item 1"}, {"text":"item 2"}].

.EXAMPLE
    pwsh New-TestReport.ps1 -Title "Add user avatar upload" -IssueNumber "123" `
      -Tester "Harris" -Date "2026/07/15" `
      -Items @("Uploading an image writes the correct path to the database","Deleting the avatar removes the database record") `
      -OutputDir "$HOME/Desktop"
#>

param(
    [Parameter(Mandatory = $true)][string]$Title,
    [Parameter(Mandatory = $true)][string]$IssueNumber,
    [Parameter(Mandatory = $true)][string]$Tester,
    [string]$Date = (Get-Date).ToString("yyyy/MM/dd"),
    [string[]]$Items,
    [string]$ItemsJson,
    [string]$OutputDir = [Environment]::GetFolderPath("Desktop"),

    # Localizable labels — override these to match the user's language.
    [string]$ReportLabel = "TestReport",
    [string]$DateLabel = "Date: ",
    [string]$TesterLabel = "Tester: ",
    [string]$SummaryHeading = "1. Test Result Summary",
    [string]$DetailHeading = "2. Test Item Details",
    [string]$ColNoHeader = "No.",
    [string]$ColItemHeader = "Test Item",
    [string]$ColResultHeader = "Result (Pass/Failed)",
    [string]$ResultLabel = "Result: "
)

function Escape-Xml {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $Text = $Text -replace '&', '&amp;'
    $Text = $Text -replace '<', '&lt;'
    $Text = $Text -replace '>', '&gt;'
    $Text = $Text -replace '"', '&quot;'
    $Text = $Text -replace "'", '&apos;'
    return $Text
}

if ($ItemsJson) {
    $parsed = Get-Content -Raw -Path $ItemsJson | ConvertFrom-Json
    if ($parsed.Count -gt 0 -and ($parsed[0].PSObject.Properties.Name -contains 'text')) {
        $Items = $parsed | ForEach-Object { $_.text }
    }
    else {
        $Items = $parsed
    }
}

if (-not $Items -or $Items.Count -eq 0) {
    throw "No test items: pass -Items or -ItemsJson"
}

$dateCompact = ($Date -replace '[/\-\.]', '')
$safeTester = $Tester -replace '[\\/:*?"<>|]', ''
$safeReportLabel = $ReportLabel -replace '[\\/:*?"<>|]', ''
$fileName = "Issue${IssueNumber}${safeReportLabel}_${dateCompact}_${safeTester}.docx"

$buildDir = Join-Path $env:TEMP ("testreport_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "_rels") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "word\_rels") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildDir "docProps") -Force | Out-Null

# ---------- static parts ----------

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
</Types>
'@
Set-Content -LiteralPath (Join-Path $buildDir "[Content_Types].xml") -Value $contentTypes -Encoding UTF8

$rootRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
</Relationships>
'@
Set-Content -Path (Join-Path $buildDir "_rels\.rels") -Value $rootRels -Encoding UTF8

$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
Set-Content -Path (Join-Path $buildDir "word\_rels\document.xml.rels") -Value $docRels -Encoding UTF8

# ascii/hAnsi default to Calibri (Word's normal Latin default); eastAsia falls back
# to Microsoft JhengHei so CJK text still renders correctly if the user's content
# happens to contain it, regardless of report language.
$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:eastAsia="Microsoft JhengHei" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
  </w:style>
</w:styles>
'@
Set-Content -Path (Join-Path $buildDir "word\styles.xml") -Value $styles -Encoding UTF8

$coreTitle = Escape-Xml "Issue$IssueNumber $ReportLabel"
$coreCreator = Escape-Xml $Tester
$core = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>$coreTitle</dc:title>
  <dc:creator>$coreCreator</dc:creator>
</cp:coreProperties>
"@
Set-Content -Path (Join-Path $buildDir "docProps\core.xml") -Value $core -Encoding UTF8

# ---------- dynamic part: word/document.xml ----------
# Page: A4, "Moderate" margins (top/bottom 1440 twips = 2.54cm, left/right 1080 twips = 1.91cm)
# Usable content width = 11906 - 1080*2 = 9746 twips, 3 columns roughly 8% / 70% / 22%

$contentWidth = 9746
$colNo = 800
$colItem = 6800
$colRes = 2146

$titleEsc = Escape-Xml $Title
$dateEsc = Escape-Xml $Date
$testerEsc = Escape-Xml $Tester
$dateLabelEsc = Escape-Xml $DateLabel
$testerLabelEsc = Escape-Xml $TesterLabel
$summaryHeadingEsc = Escape-Xml $SummaryHeading
$detailHeadingEsc = Escape-Xml $DetailHeading
$colNoHeaderEsc = Escape-Xml $ColNoHeader
$colItemHeaderEsc = Escape-Xml $ColItemHeader
$colResultHeaderEsc = Escape-Xml $ColResultHeader
$resultLabelEsc = Escape-Xml $ResultLabel

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$sb.AppendLine('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>')

[void]$sb.AppendLine("<w:p><w:pPr><w:spacing w:after=""120""/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=""32""/><w:szCs w:val=""32""/></w:rPr><w:t>$titleEsc</w:t></w:r></w:p>")
[void]$sb.AppendLine("<w:p><w:pPr><w:spacing w:after=""40""/></w:pPr><w:r><w:t>$dateLabelEsc$dateEsc</w:t></w:r></w:p>")
[void]$sb.AppendLine("<w:p><w:pPr><w:spacing w:after=""200""/></w:pPr><w:r><w:t>$testerLabelEsc$testerEsc</w:t></w:r></w:p>")

[void]$sb.AppendLine("<w:p><w:pPr><w:spacing w:before=""200"" w:after=""120""/><w:pBdr><w:bottom w:val=""single"" w:sz=""6"" w:space=""4"" w:color=""999999""/></w:pBdr></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=""26""/><w:szCs w:val=""26""/></w:rPr><w:t>$summaryHeadingEsc</w:t></w:r></w:p>")

[void]$sb.AppendLine("<w:tbl><w:tblPr><w:tblW w:w=""$contentWidth"" w:type=""dxa""/><w:tblBorders><w:top w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""000000""/><w:left w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""000000""/><w:bottom w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""000000""/><w:right w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""000000""/><w:insideH w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""000000""/><w:insideV w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""000000""/></w:tblBorders><w:tblLayout w:type=""fixed""/></w:tblPr>")
[void]$sb.AppendLine("<w:tblGrid><w:gridCol w:w=""$colNo""/><w:gridCol w:w=""$colItem""/><w:gridCol w:w=""$colRes""/></w:tblGrid>")
[void]$sb.AppendLine("<w:tr><w:tc><w:tcPr><w:tcW w:w=""$colNo"" w:type=""dxa""/></w:tcPr><w:p><w:pPr><w:jc w:val=""center""/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t>$colNoHeaderEsc</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW w:w=""$colItem"" w:type=""dxa""/></w:tcPr><w:p><w:pPr><w:jc w:val=""center""/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t>$colItemHeaderEsc</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW w:w=""$colRes"" w:type=""dxa""/></w:tcPr><w:p><w:pPr><w:jc w:val=""center""/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t>$colResultHeaderEsc</w:t></w:r></w:p></w:tc></w:tr>")

for ($i = 0; $i -lt $Items.Count; $i++) {
    $n = $i + 1
    $itemEsc = Escape-Xml $Items[$i]
    [void]$sb.AppendLine("<w:tr><w:tc><w:tcPr><w:tcW w:w=""$colNo"" w:type=""dxa""/></w:tcPr><w:p><w:pPr><w:jc w:val=""center""/></w:pPr><w:r><w:t>$n</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW w:w=""$colItem"" w:type=""dxa""/></w:tcPr><w:p><w:r><w:t>$itemEsc</w:t></w:r></w:p></w:tc><w:tc><w:tcPr><w:tcW w:w=""$colRes"" w:type=""dxa""/></w:tcPr><w:p/></w:tc></w:tr>")
}
[void]$sb.AppendLine('</w:tbl>')

[void]$sb.AppendLine("<w:p><w:pPr><w:spacing w:before=""300"" w:after=""120""/><w:pBdr><w:bottom w:val=""single"" w:sz=""6"" w:space=""4"" w:color=""999999""/></w:pBdr></w:pPr><w:r><w:rPr><w:b/><w:sz w:val=""26""/><w:szCs w:val=""26""/></w:rPr><w:t>$detailHeadingEsc</w:t></w:r></w:p>")

for ($i = 0; $i -lt $Items.Count; $i++) {
    $n = $i + 1
    $itemEsc = Escape-Xml $Items[$i]
    [void]$sb.AppendLine("<w:p><w:pPr><w:spacing w:before=""200"" w:after=""60""/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t>$n. $itemEsc</w:t></w:r></w:p>")
    [void]$sb.AppendLine("<w:tbl><w:tblPr><w:tblW w:w=""$contentWidth"" w:type=""dxa""/><w:tblBorders><w:top w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""999999""/><w:left w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""999999""/><w:bottom w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""999999""/><w:right w:val=""single"" w:sz=""4"" w:space=""0"" w:color=""999999""/></w:tblBorders><w:tblLayout w:type=""fixed""/></w:tblPr><w:tblGrid><w:gridCol w:w=""$contentWidth""/></w:tblGrid>")
    [void]$sb.AppendLine("<w:tr><w:trPr><w:trHeight w:val=""1200"" w:hRule=""atLeast""/></w:trPr><w:tc><w:tcPr><w:tcW w:w=""$contentWidth"" w:type=""dxa""/></w:tcPr><w:p><w:r><w:rPr><w:color w:val=""666666""/><w:sz w:val=""20""/><w:szCs w:val=""20""/></w:rPr><w:t>$resultLabelEsc</w:t></w:r></w:p><w:p/><w:p/></w:tc></w:tr></w:tbl>")
}

[void]$sb.AppendLine('<w:p/>')
[void]$sb.AppendLine('<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1080" w:bottom="1440" w:left="1080" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr>')
[void]$sb.AppendLine('</w:body></w:document>')

Set-Content -Path (Join-Path $buildDir "word\document.xml") -Value $sb.ToString() -Encoding UTF8

# ---------- zip into .docx and output ----------

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$outPath = Join-Path $OutputDir $fileName
Compress-Archive -Path "$buildDir\*" -DestinationPath $outPath -CompressionLevel Optimal -Force

Remove-Item -Path $buildDir -Recurse -Force

Write-Output $outPath
