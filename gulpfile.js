import { series, watch, src, dest } from "gulp";
import newer from "gulp-newer";
import path from "path";
import replace from "gulp-replace";
import touch from "gulp-touch-cmd";
import zip from "gulp-zip";
import fs from "fs";
import { deleteSync } from "del";
// work around to easily load json in this ES module
import { createRequire } from "module";
const require = createRequire(import.meta.url);
let packageJson = require("./package.json");

class util {
  static get name() {
    return packageJson.title.replace(/\s+/gm, "");
  }
  static get distro() {
    return `./${util.name}-${packageJson.version}`;
  }
}

const SRC = "src";
let DEST = path.join(
  process.env.WOW_ADDON_DEST_FOLDER,
  packageJson.title.replace(/\s+/gm, "")
);

const MERCH_CONFIG = {
  watchers: [
    class {
      static get glob() {
        return SRC + "/**/*.lua";
      }
      static get opts() {
        return { ignoreInitial: false };
      }
      static get taskFn() {
        let luaCopy = (cb) => {
          src(this.glob).pipe(newer(DEST)).pipe(dest(DEST));
          cb();
        };
        return luaCopy;
      }
    },
    class {
      static get glob() {
        return SRC + "/**/*.xml";
      }
      static get opts() {
        return { ignoreInitial: false };
      }
      static get taskFn() {
        let xmlCopy = () => {
          return src(this.glob).pipe(dest(DEST));
        };
        return xmlCopy;
      }
    },
    class {
      static get glob() {
        return path.join(SRC, "**", "assets", "*.png");
      }
      static get opts() {
        return { ignoreInitial: false };
      }
      static get taskFn() {
        let pngCopy = (cb) => {
          src(this.glob, { encoding: false })
            .pipe(newer(DEST))
            .pipe(dest(DEST));
          cb();
        };
        return pngCopy;
      }
    },
    class {
      static get glob() {
        return path.join(SRC, "**", "assets", "attribution.md");
      }
      static get opts() {
        return { ignoreInitial: false };
      }
      static get taskFn() {
        let attributionCopy = (cb) => {
          src(this.glob).pipe(newer(DEST)).pipe(dest(DEST));
          cb();
        };
        return attributionCopy;
      }
    },
    class {
      static get glob() {
        return path.join(SRC, "*.toc");
      }
      static get opts() {
        return { ignoreInitial: false };
      }
      static get taskFn() {
        let tocCopy = () => {
          return src(this.glob)
            .pipe(
              replace(
                /^[\s]*##[\s]*Title[\s]*:.*$/gm,
                "## Title: " + packageJson.title
              )
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
                `## SavedVariables: ${packageJson.title.replace(/\s+/gm, "")}DB`
              )
            )
            .pipe(dest(DEST));
        };
        return tocCopy;
      }
    },
    class {
      static get glob() {
        return "./package.json";
      }
      static get opts() {
        return { ignoreInitial: true };
      }
      static get taskFn() {
        const reloadPackageJson = () => {
          // reload package.json and trigger the toc task
          delete require.cache[require.resolve("./package.json")];
          packageJson = require("./package.json");
          return src(path.join(SRC, "*.toc")).pipe(touch());
        };
        return reloadPackageJson;
      }
    },
  ],
};
// default is to move changes to the wow addon folder for easy code/test iterations.
export default () => {
  console.log(DEST);
  MERCH_CONFIG.watchers.forEach((e) => {
    watch(e.glob, e.opts, e.taskFn);
  });
};
/*
 build/archive/deploy
 */
export const build = series(MERCH_CONFIG.watchers.map((p) => p.taskFn));

export const distClean = (cb) => {
  const folder = path.join(process.env.TEMP, `${util.distro}`);
  if (fs.existsSync(folder)) {
    const distroGlob = folder + "/*/";
    deleteSync([distroGlob], { force: true });
  }
  cb();
};

function distCreate() {
  return src(`${util.name}/**/*`, {
    cwd: process.env.WOW_ADDON_PATH,
  }).pipe(dest(util.distro + `/${util.name}`, { cwd: process.env.TEMP }));
}

function distArchive() {
  const zipFileName = `${packageJson.title}-${packageJson.version}.zip`;
  return src(`${util.distro}/**`, { cwd: process.env.TEMP })
    .pipe(zip(zipFileName))
    .pipe(dest("./dist"));
}

export const dist = series(build, distClean, distCreate, distArchive);
