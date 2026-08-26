import { readdir, readFile } from 'node:fs/promises'
import { extname, join, relative } from 'node:path'

const ROOT = new URL('../src/', import.meta.url)
const MAX_LINES = 450
const CHECKED_EXTENSIONS = new Set(['.js', '.jsx', '.css'])

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true })
  const files = []

  for (const entry of entries) {
    const fullPath = join(directory, entry.name)
    if (entry.isDirectory()) files.push(...await walk(fullPath))
    else if (CHECKED_EXTENSIONS.has(extname(entry.name))) files.push(fullPath)
  }

  return files
}

const sourceRoot = ROOT.pathname
const files = await walk(sourceRoot)
const violations = []

for (const file of files) {
  const content = await readFile(file, 'utf8')
  const lines = content === '' ? 0 : content.split(/\r?\n/).length
  if (lines > MAX_LINES) {
    violations.push({ file: relative(sourceRoot, file), lines })
  }
}

if (violations.length) {
  console.error(`Fameverse source limit exceeded (${MAX_LINES} lines max):`)
  for (const violation of violations) {
    console.error(`- src/${violation.file}: ${violation.lines} lines`)
  }
  console.error('Split the file by responsibility before merging or deploying.')
  process.exit(1)
}

console.log(`Source line guard passed: ${files.length} files checked, all <= ${MAX_LINES} lines.`)
