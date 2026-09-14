import { series, watch, src, dest } from "gulp";
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
  // path to icon used by WoW's AddOn list dialog e.g. Game Menu -> AddOns
  static get iconTexture() {
    return `Interface\\AddOns\\${util.name}\\assets\\icon`;
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
  const output = path.join("build", util.name, "assets");
  const files = ["src/assets/icon.tga"];
  return src(files, { ignoreInitial: false, encoding: false })
    .pipe(dest(output))
    .pipe(touch());
}
//////////////////////////////////
function toc(cb) {
  const output = path.join("build", util.name);
  return src(`src/${util.name}.toc`)
    .pipe(
      replace(
        /^[\s]*##[\s]*Title(?!-)[\s]*:.*$/gm,
        "## Title: " + packageJson.title,
      ),
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Description(?!-)[\s]*:.*$/gm,
        "## Description: " + packageJson.description,
      ),
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Version[\s]*:.*$/gm,
        "## Version: " + packageJson.version,
      ),
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Interface[\s]*:.*$/gm,
        "## Interface: " + packageJson.interface,
      ),
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*Author[\s]*:.*$/gm,
        "## Author: " + packageJson.author,
      ),
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*SavedVariables[\s]*:.*$/gm,
        `## SavedVariables: ${util.name}DB`,
      ),
    )
    .pipe(
      replace(
        /^[\s]*##[\s]*IconTexture[\s]*:.*$/gm,
        `## IconTexture: ${util.iconTexture}`,
      ),
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
    series(configure, codes, assets, toc, addons),
  );
}
//////////////////////////////////
function streamDone(stream) {
  return new Promise((resolve, reject) => {
    stream.once("error", reject);
    stream.once("finish", resolve);
    stream.once("end", resolve);
  });
}

async function addons() {
  const wowRoot = (process.env.WOW_FOLDER ?? "").replace(/[;\\/]+$/, "");
  if (!wowRoot) {
    throw new Error("WOW_FOLDER is not set");
  }

  const wowFlavors = ["_anniversary_", "_classic_era_", "_classic_"];
  const addonBuild = path.join("build", util.name);
  const glob = `${addonBuild.replaceAll("\\", "/")}/**/*`;

  for (const flavor of wowFlavors) {
    const output = path.join(
      wowRoot,
      flavor,
      "Interface",
      "AddOns",
      util.name,
    );
    console.log("Copying build to " + output);
    deleteSync([output.replaceAll("\\", "/")], { force: true });
    await streamDone(
      src(glob, { encoding: false, base: addonBuild })
        .pipe(dest(output))
        .pipe(touch()),
    );
  }
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
