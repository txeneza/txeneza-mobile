const fs = require('fs');
const path = require('path');

// Configuration
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const customPath = args.find(arg => !arg.startsWith('-'));
const targetDir = customPath ? path.resolve(customPath) : path.join(__dirname, 'lib');

function walkDir(dir, callback) {
  if (!fs.existsSync(dir)) return;
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(dirPath);
  });
}

/**
 * Parses file content and replaces .withOpacity(args) with .withValues(alpha: args)
 * handles nested parentheses and ignores comments.
 */
function updateContent(content) {
  let result = '';
  let i = 0;
  let len = content.length;
  let count = 0;

  while (i < len) {
    // 1. Skip single line comments
    if (content[i] === '/' && content[i + 1] === '/') {
      result += '//';
      i += 2;
      while (i < len && content[i] !== '\n') {
        result += content[i];
        i++;
      }
      continue;
    }

    // 2. Skip multi-line comments
    if (content[i] === '/' && content[i + 1] === '*') {
      result += '/*';
      i += 2;
      while (i < len && !(content[i] === '*' && content[i + 1] === '/')) {
        result += content[i];
        i++;
      }
      if (i < len) {
        result += '*/';
        i += 2;
      }
      continue;
    }

    // 3. Match .withOpacity(
    if (content.substring(i, i + 13) === '.withOpacity(') {
      let startArgsIdx = i + 13;
      let depth = 1;
      let j = startArgsIdx;
      
      while (j < len && depth > 0) {
        let char = content[j];
        if (char === '(') {
          depth++;
        } else if (char === ')') {
          depth--;
        }
        j++;
      }

      if (depth === 0) {
        let args = content.substring(startArgsIdx, j - 1);
        result += `.withValues(alpha: ${args})`;
        i = j;
        count++;
        continue;
      }
    }

    result += content[i];
    i++;
  }

  return { result, count };
}

console.log(`Scanning directory: ${targetDir}`);
if (dryRun) {
  console.log('Running in DRY-RUN mode. No files will be modified.');
}

let fileCount = 0;
let matchCount = 0;

walkDir(targetDir, (filePath) => {
  if (path.extname(filePath) !== '.dart') return;

  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const { result, count } = updateContent(content);

    if (count > 0) {
      if (!dryRun) {
        fs.writeFileSync(filePath, result, 'utf8');
      }
      console.log(`${dryRun ? '[Dry-Run] Would update' : 'Updated'}: ${path.relative(__dirname, filePath)} (${count} replacement${count > 1 ? 's' : ''})`);
      fileCount++;
      matchCount += count;
    }
  } catch (err) {
    console.error(`Error processing file ${filePath}:`, err.message);
  }
});

console.log(`\nScan finished. ${dryRun ? 'Would update' : 'Updated'} ${fileCount} file(s) with a total of ${matchCount} replacement(s).`);

