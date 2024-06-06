import { series, watch, src, dest } from "gulp";
import newer from "gulp-newer";
import path from "path";
import replace from "gulp-replace";
import touch from "gulp-touch-cmd";
import { deleteSync } from "del";
import { execSync } from "child_process";
import zip from "gulp-zip";

// work around to easily load json in this ES module
import { createRequire } from "module";

const require = createRequire(import.meta.url);
let packageJson = require("./package.json");
//////////////////////////////////
class util {
  static get name() {
    return packageJson.title.replace(/(\s)+/gm, "");
  }
  static get archiveName() {
    return `./${util.name}-${packageJson.version}`;
  }
  static get zipName() {
    return `${util.archiveName}.zip`;
  }
}
//////////////////////////////////
function configure(cb) {
  const output = path.join("build", util.name);
  delete require.cache[require.resolve("./package.json")];
  packageJson = require("./package.json");

  return src("package.json", { ignoreInitial: false })
    .pipe(dest(output))
    .pipe(touch());
}
//////////////////////////////////
function codes(cb) {
  const output = path.join("build", util.name);
  return src(["src/**/*.lua", "src/**/*.xml"], { ignoreInitial: false })
    .pipe(dest(output))
    .pipe(touch());
}
function attributions(cb) {
  const output = path.join("build", util.name);
  return src(["src/**/attribution.*"], { ignoreInitial: false })
    .pipe(dest(output))
    .pipe(touch());
}
//////////////////////////////////
function assets(cb) {
  const output = path.join("build", util.name);
  return src("src/**/*.png", { ignoreInitial: false, encoding: false })
    .pipe(dest(output))
    .pipe(touch());
}
//////////////////////////////////
function toc(cb) {
  const output = path.join("build", util.name);
  return src(`src/${util.name}.toc`)
    .pipe(
      replace(/^[\s]*##[\s]*Title[\s]*:.*$/gm, "## Title: " + packageJson.title)
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Description[\s]*:.*$/gm,
        "## Description: " + packageJson.description
      )
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Version[\s]*:.*$/gm,
        "## Version: " + packageJson.version
      )
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Interface[\s]*:.*$/gm,
        "## Interface: " + packageJson.interface
      )
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Author[\s]*:.*$/gm,
        "## Author: " + packageJson.author
      )
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*SavedVariables[\s]*:.*$/gm,
        `## SavedVariables: ${util.name}DB`
      )
    )
    .pipe(dest(output))
    .pipe(touch());
}

//////////////////////////////////
// watch and write changes to wow addon folder.
function dev(_) {
  clean();
  watch(
    ["package.json", "src/**/*"],
    { ignoreInitial: false },
    series(configure, codes, assets, toc, addons)
  );
}
//////////////////////////////////
function addons(cb) {
  const output = process.env.WOW_ADDON_DEST_FOLDER;
  console.log("Copying build to " + output);
  return src("build/**/*", { ignoreInitial: false, encoding: false })
    .pipe(newer(output))
    .pipe(dest(output))
    .pipe(touch());
}
//////////////////////////////////
export default dev;
//////////////////////////////////
export function clean(cb) {
  deleteSync(["build/*", "dist/" + util.zipName], { force: true });
  if (cb) cb();
}
//////////////////////////////////
export function archive(cb) {
  setTimeout(() => {
    src("build/**", { encoding: false })
      .pipe(zip(util.archiveName + ".zip"))
      .pipe(dest("dist"));
    cb();
  }, 1000);
}
//////////////////////////////////
export const build = series(clean, codes, assets, toc, attributions, archive);
