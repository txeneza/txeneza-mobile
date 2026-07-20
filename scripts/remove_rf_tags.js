const fs = require('fs');
const path = require('path');

const targetDir = path.join(__dirname, '..', 'lib');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(filePath));
    } else if (filePath.endsWith('.dart')) {
      results.push(filePath);
    }
  });
  return results;
}

function cleanFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  const original = content;

  // Replace literal RF-xxx patterns safely without eating code parentheses
  // 1. " (RF-123)" or " (RF-123, RF-456)" -> ""
  content = content.replace(/\s*\(RF-\d+(?:,\s*RF-\d+)*\)/gi, '');

  // 2. "// RF-123" or "RF-123:" -> ""
  content = content.replace(/\s*RF-\d+(\/RF-\d+)?(:)?/gi, '');

  if (content !== original) {
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`[REMOVED RF TAGS] ${path.relative(process.cwd(), filePath)}`);
    return true;
  }
  return false;
}

console.log('Pesquisando e removendo marcas RF-xxx...');
const files = walk(targetDir);
let count = 0;
files.forEach((file) => {
  if (cleanFile(file)) {
    count++;
  }
});

console.log(`Concluído! ${count} ficheiro(s) limpo(s).`);
