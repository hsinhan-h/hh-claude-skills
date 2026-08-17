#!/usr/bin/env node
/**
 * Extract paragraphs/table-rows containing a given highlight mark from a
 * Word document's word/document.xml, with surrounding structural context
 * (table header row, nearby heading text).
 *
 * Usage:
 *   node extract-highlights.js <document.xml> <color> <output.json>
 *
 * <color>:
 *   - A Word highlighter name for character highlight marks (w:highlight):
 *     yellow | green | cyan | magenta | blue | red | darkYellow | darkGreen |
 *     darkCyan | darkMagenta | darkRed | darkBlue | darkGray | lightGray |
 *     black | white
 *   - OR a 6-digit hex color (e.g. FFFF00) to match cell/run shading (w:shd
 *     fill=) instead — use this if the mark in the doc is a background color
 *     rather than the highlighter tool.
 */
const fs = require('fs');

const [, , xmlPath, colorArg, outPath] = process.argv;
if (!xmlPath || !colorArg || !outPath) {
  console.error('Usage: node extract-highlights.js <document.xml> <color> <output.json>');
  process.exit(1);
}

const xml = fs.readFileSync(xmlPath, 'utf8');
const isHex = /^[0-9A-Fa-f]{6}$/.test(colorArg);

function unesc(s) {
  return s
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'");
}

// IMPORTANT: require a word boundary after "w:t" (either ">" or whitespace)
// so this doesn't also match <w:tcPr>, <w:tcW>, <w:tcBorders>, etc.
function getText(fragment) {
  const texts = [];
  const tRegex = /<w:t(?:\s[^>]*)?>([\s\S]*?)<\/w:t>/g;
  let m;
  while ((m = tRegex.exec(fragment)) !== null) texts.push(m[1]);
  return unesc(texts.join(''));
}

function getCellTextMultiPara(cellXml) {
  const paraRegex = /<w:p[ >][\s\S]*?<\/w:p>/g;
  const paras = [];
  let m;
  while ((m = paraRegex.exec(cellXml)) !== null) {
    const t = getText(m[0]).trim();
    if (t) paras.push(t);
  }
  return paras.join('\n');
}

function getCellsFromRow(rowXml) {
  const cells = [];
  const tcRegex = /<w:tc[ >][\s\S]*?<\/w:tc>/g;
  let m;
  while ((m = tcRegex.exec(rowXml)) !== null) {
    cells.push(getCellTextMultiPara(m[0]));
  }
  return cells;
}

const markRegex = isHex
  ? new RegExp('<w:shd[^>]*w:fill="' + colorArg + '"[^>]*/?>', 'gi')
  : new RegExp('<w:highlight w:val="' + colorArg + '"\\s*/?>', 'gi');

const positions = [];
let mm;
while ((mm = markRegex.exec(xml)) !== null) positions.push(mm.index);

console.error(`Found ${positions.length} "${colorArg}" mark(s) in ${xmlPath}`);

const results = [];
const seen = new Set();

for (const pos of positions) {
  const trStart = Math.max(xml.lastIndexOf('<w:tr ', pos), xml.lastIndexOf('<w:tr>', pos));
  const trCloseBefore = xml.lastIndexOf('</w:tr>', pos);

  if (trStart !== -1 && trStart > trCloseBefore) {
    // Highlight sits inside a table row.
    const trEnd = xml.indexOf('</w:tr>', pos) + '</w:tr>'.length;
    const key = 'row:' + trStart + '-' + trEnd;
    if (seen.has(key)) continue;
    seen.add(key);

    const entry = { type: 'table-row' };
    entry.cells = getCellsFromRow(xml.substring(trStart, trEnd));

    // Header row = first <w:tr> in the enclosing <w:tbl>, for column labels.
    const tblStart = xml.lastIndexOf('<w:tbl>', trStart);
    if (tblStart !== -1) {
      const firstTrStart = xml.indexOf('<w:tr', tblStart);
      if (firstTrStart !== -1 && firstTrStart < trStart) {
        const firstTrEnd = xml.indexOf('</w:tr>', firstTrStart) + '</w:tr>'.length;
        entry.header = getCellsFromRow(xml.substring(firstTrStart, firstTrEnd));
      }

      // Last few non-empty paragraphs before the table, as heading/section context.
      const windowStart = Math.max(0, tblStart - 4000);
      const before = xml.substring(windowStart, tblStart);
      const paraRegex = /<w:p[ >][\s\S]*?<\/w:p>/g;
      const ctx = [];
      let pm;
      while ((pm = paraRegex.exec(before)) !== null) {
        const t = getText(pm[0]).trim();
        if (t) ctx.push(t);
      }
      entry.context = ctx.slice(-3);
    }

    results.push(entry);
  } else {
    // Standalone paragraph (not inside a table).
    const pStart = Math.max(xml.lastIndexOf('<w:p ', pos), xml.lastIndexOf('<w:p>', pos));
    const pEnd = xml.indexOf('</w:p>', pos) + '</w:p>'.length;
    const key = 'p:' + pStart + '-' + pEnd;
    if (seen.has(key)) continue;
    seen.add(key);

    const text = getText(xml.substring(pStart, pEnd)).trim();
    if (!text) continue;
    results.push({ type: 'paragraph', text });
  }
}

fs.writeFileSync(outPath, JSON.stringify(results, null, 2), 'utf8');
console.error(`Wrote ${results.length} unique row/paragraph entries to ${outPath}`);
