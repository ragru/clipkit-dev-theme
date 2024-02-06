const esbuild = require("esbuild");
const fs = require("fs");
const path = require("path");
const sass = require("sass");
const chokidar = require("chokidar");
const minimatch = require("minimatch").minimatch;

const config = {
  entryDir: "../src",
  outputDir: "../dest",
};

const ignoredFiles = ["**/.DS_Store"];

function ensureDirectoryExistence(filePath) {
  const dirname = path.dirname(filePath);
  if (fs.existsSync(dirname)) {
    return true;
  }
  fs.mkdirSync(dirname, { recursive: true });
}

function findFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  files.forEach((file) => {
    const filePath = path.join(dir, file);
    if (ignoredFiles.some((pattern) => minimatch(filePath, pattern))) return;
    if (fs.statSync(filePath).isDirectory()) {
      findFiles(filePath, fileList);
    } else {
      fileList.push(filePath);
    }
  });
  return fileList;
}

function copyFile(src, dest) {
  ensureDirectoryExistence(dest);
  fs.copyFileSync(src, dest);
}

function compileSass(src, dest) {
  const result = sass.compile(src, { loadPaths: [path.dirname(src)] });
  fs.writeFileSync(dest, result.css);
}

function getOutputFilePath(srcFilePath) {
  const relativePath = path.relative(config.entryDir, srcFilePath);
  return path.join(config.outputDir, relativePath);
}

function processFile(srcFilePath) {
  const outFilePath = getOutputFilePath(srcFilePath);
  if (
    fs.existsSync(outFilePath) &&
    fs.statSync(srcFilePath).mtime <= fs.statSync(outFilePath).mtime
  ) {
    return;
  }

  if (srcFilePath.endsWith(".js")) {
    esbuild
      .build({
        entryPoints: [srcFilePath],
        bundle: true,
        outfile: outFilePath,
      })
      .then(() => console.log(`Bundled: ${srcFilePath}`))
      .catch((error) =>
        console.error(`Error during bundling ${srcFilePath}:`, error)
      );
  } else if (srcFilePath.endsWith(".scss")) {
    try {
      compileSass(srcFilePath, outFilePath.replace(/\.scss$/, ".css"));
      console.log(`Compiled: ${srcFilePath}`);
    } catch (error) {
      console.error(`Error during compiling ${srcFilePath}:`, error);
    }
  } else {
    try {
      copyFile(srcFilePath, outFilePath);
      console.log(`Copied: ${srcFilePath}`);
    } catch (error) {
      console.error(`Error during copying ${srcFilePath}:`, error);
    }
  }
}

findFiles(config.entryDir).forEach(processFile);

const watcher = chokidar.watch(config.entryDir, { ignored: ignoredFiles });
watcher.on("add", processFile).on("change", processFile);
