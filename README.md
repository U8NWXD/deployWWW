# `deployWWW`: A script for deploying static websites

`deployWWW` can deploy static websites (buildable by Jekyll) to hosting
on [GitHub Pages](https://pages.github.com),
[Stanford AFS](https://uit.stanford.edu/service/web/centralhosting/howto_user),
or [Keybase](https://keybase.io).

## Usage

```
Usage: deploy.sh [-h] (-g username [-t] | -s sunet [-r repo_dir] [-w www_path] | -k keybase_username) [-b build_dir]
  -g: Use GitHub Pages
  -s: Use Stanford AFS Web Hosting
  -t: Use HTTPS to connect to GitHub repository
  -r: Store the remote repository at the specified path
  -w: Put the compiled HTML files at the specified path
  -k: Host in Keybase public folder
  -b: Get the built website from the specified path
```

Defaults:
* `build_dir`: `_site`
* `repo_dir`: `~/Documents/git_hosted/site.git`
* `www_path`: `~/WWW/site`

Note that if the `repo_dir` or `www_path` directories don't exist, they
will be created for you. If you are hosting on Stanford AFS, it is
**highly recommended** that you setup
[kerberos](https://uit.stanford.edu/service/kerberos) for SSH, otherwise
it will be very annoying to type in your password over and over!

In your jekyll `_config.yml` file, set `baseurl: null`. This line will
be replaced with the correct base URL for your hosting option by the
script, and the changes will be un-done by the time the script
completes.

### Examples

* Host website on GitHub pages with username `example`:
  `deploy.sh -g example`
* Host website on Stanford AFS, where your SuNet is `example`:
  `deploy.sh -s example`
* Host website on Keybase, where your username is `example`:
  `deploy.sh -k example`

## How it Works

The `deploy.sh` script works like this:

* Interprets the options you provide
* Computes the correct base url and inserts it into your jekyll config
  file
* Runs `jekyll build` to build your website
* If you use keybase, copies the contents of `build_dir` to your public
  keybase folder at `/keybase/public/your_username/`
* If you use GitHub or Stanford AFS:
    * Creates a new `git` repo inside `build_dir`
    * Uses `git push` to upload your site from the newly-created git
      repo to your hosting platform

## Attributions

Copyright (c) 2019 Christopher Skalnik (https://github.com/U8NWXD)
<cs.temporary@icloud.com>

This tool is deployWWW (https://github.com/U8NWXD/deployWWW).
You may not use this tool except in compliance with the license in
[LICENSE.txt](LICENSE.txt), which can be found at the project link
above. This project comes with ABSOLUTELY NO WARRANTY. See LICENSE.txt 
for details.
