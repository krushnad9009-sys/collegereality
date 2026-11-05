"""Assemble collegekundli.com for Firebase Hosting.

Output: build/hosting
  /       Flutter Web release build of lib/main.dart (--base-href /), so the
          website is the same app as on Android
  + the static policy pages from hosting/public (/terms, /privacy-policy,
          /refund-policy, /shipping-policy, /contact, app-ads.txt, ...).
          hosting/public/index.html (the old HTML landing page) is not
          shipped; old /app links are redirected to / in firebase.json.

firebase.json serves build/hosting and runs this as the hosting predeploy, so
`firebase deploy --only hosting` always ships a fresh build.

Optional environment variables:
  APP_CHECK_RECAPTCHA_SITE_KEY  passed as --dart-define; without it App Check
                                stays off on web.
  SKIP_FLUTTER_BUILD=1          reuse the existing build/web instead of
                                rebuilding the app (static pages are always
                                re-copied).
"""
import os
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
STATIC = ROOT / 'hosting' / 'public'
FLUTTER_OUT = ROOT / 'build' / 'web'
OUT = ROOT / 'build' / 'hosting'
STATIC_SKIP = {'index.html'}  # the app owns /
DART_DEFINES = ['APP_CHECK_RECAPTCHA_SITE_KEY']


def build_flutter():
    cmd = ['flutter', 'build', 'web', '--release', '-t', 'lib/main.dart',
           '--base-href', '/']
    for name in DART_DEFINES:
        value = os.environ.get(name, '').strip()
        if value:
            cmd.append(f'--dart-define={name}={value}')
            print(f'Using {name} from the environment.')
        else:
            print(f'Note: {name} not set; building without it.')
    # flutter build doesn't remove stale files, so start from an empty output.
    shutil.rmtree(FLUTTER_OUT, ignore_errors=True)
    # shell=True so Windows resolves flutter.bat.
    subprocess.run(subprocess.list2cmdline(cmd) if os.name == 'nt' else cmd,
                   cwd=ROOT, check=True, shell=os.name == 'nt')


def main():
    if os.environ.get('SKIP_FLUTTER_BUILD') == '1' and (FLUTTER_OUT / 'main.dart.js').exists():
        print('SKIP_FLUTTER_BUILD=1: reusing build/web')
    else:
        build_flutter()
    app_index = FLUTTER_OUT / 'index.html'
    if not app_index.exists() or not (FLUTTER_OUT / 'main.dart.js').exists():
        sys.exit('build/web is missing the Flutter build output.')
    if '<base href="/">' not in app_index.read_text(encoding='utf-8'):
        sys.exit('build/web was not built with --base-href /; rebuild without SKIP_FLUTTER_BUILD.')

    shutil.rmtree(OUT, ignore_errors=True)
    shutil.copytree(FLUTTER_OUT, OUT)
    for item in STATIC.iterdir():
        if item.name in STATIC_SKIP:
            continue
        dest = OUT / item.name
        if dest.exists():
            sys.exit(f'hosting/public/{item.name} would overwrite a Flutter build file; rename it.')
        if item.is_dir():
            shutil.copytree(item, dest)
        else:
            shutil.copy2(item, dest)
    print('build/hosting is ready: web app at /, policy pages beside it')


if __name__ == '__main__':
    main()
