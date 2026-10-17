# Store Screenshot Check for Fastlane

Check a screenshot folder before a lane uploads it to App Store Connect or Google
Play. The `store_screenshot_check` action checks image data, dimensions,
transparency and set counts using `@grunersoftware/store-screenshot-specs` 0.1.0.
It returns a report and, by default, stops the lane when a file or set fails.

Add the plugin to a Fastlane project:

```sh
bundle exec fastlane add_plugin store_screenshot_check
```

Or add `gem 'fastlane-plugin-store_screenshot_check', '~> 0.1.0'` to the
project's `fastlane/Pluginfile` and run `bundle install`. The lane host needs Node.js 22 or newer,
Ruby 3.1 or newer, and Fastlane 2.220 or newer (2.x). The gem includes its
JavaScript validator and dependencies; no npm install is needed to run it.

## Use before upload

```ruby
lane :check_screenshots do
  root = File.expand_path('..', __dir__) # Fastfile is in the fastlane directory
  report = store_screenshot_check(
    workspace: root,
    directory: 'screenshots/en-US/iphone',
    target: 'apple-iphone-69'
  )
  UI.message("Checked #{report['files']} screenshots")
  # Put your existing upload action after this check.
end
```

For a Google Play phone set, use `target: 'google-phone'`. Call the action once
for each locale/device directory; it does not recursively classify an entire
Fastlane screenshot tree. Each directory should contain screenshot files only.

| Parameter | Meaning |
| --- | --- |
| `directory` | Required. One screenshot directory inside `workspace`. |
| `target` | Required. Exact target ID from the supported list below. |
| `workspace` | Root used to resolve and constrain the screenshot path. Defaults to the process working directory. Prefer an explicit absolute path. |
| `node` | Node.js executable name or path. Defaults to `node`. |
| `fail_on_error` | Default `true`. Use `false` to return invalid-file/set findings without stopping the lane. |
| `fail_on_review` | Default `false`. Use `true` to also stop for manual-review warnings. |

Invalid configuration, missing Node.js, unsupported targets, empty directories,
and directories outside the workspace always stop the lane, even when
`fail_on_error` is false. A failed lane exits unsuccessfully unless your Fastfile
explicitly catches the exception. No upload action is called by this plugin.

The returned Hash has string keys: `target`, `specsVersion`, `files`, `failures`,
`reviews`, `passes`, `results`, `errors` and `countCheck`. `results` contains image
metadata and checks with `tone`, `label`, and `detail`; `errors` contains files
that could not be inspected. `failures` counts failed files plus a failed set-count
check. `reviews` counts files needing review plus a set-count warning. The report
contains filenames and metadata, not image pixels.

## Supported targets and limits

| Target IDs | Checks |
| --- | --- |
| `apple-iphone-duo`, `apple-iphone-69`, `apple-iphone-65`, `apple-iphone-63`, `apple-iphone-61`, `apple-iphone-55`, `apple-iphone-47`, `apple-iphone-4`, `apple-iphone-35` | Exact supported sizes, PNG/JPEG, transparency, 1–10 screenshots. |
| `apple-ipad-13`, `apple-ipad-129`, `apple-ipad-11`, `apple-ipad-105`, `apple-ipad-97`, `apple-mac` | Exact supported sizes, PNG/JPEG, transparency, 1–10 screenshots. |
| `google-phone` | JPEG or 24-bit PNG without alpha, edges 320–3840px, long edge at most twice the short edge, at most 8 screenshots. |

Google requires two screenshots across device types, so a phone set with only one
image receives a review warning. Promotional dimension guidance also produces
warnings; passing those checks does not establish promotional eligibility.
Apple/Google file-size limits are not asserted. Only the target IDs in the table
are supported. Google tablet/TV/watch sets and Microsoft Store are unsupported
by this first plugin release.

PNG and JPEG files are decoded; a renamed extension or a plausible header is not
enough. PNG checks include CRCs, alpha/transparency markers, bit depth and color
type. Hidden files and subdirectories are ignored. Other visible entries count
toward the set; symlinks, special files, unsupported data and corrupt images fail.
The decoder limits are 64 MiB per file, 24 megapixels per decoded image and 100
visible non-directory entries per folder. These are validator limits, not store
requirements.

This checks one image set, not screenshot content, text overflow, required
languages, complete device coverage, account eligibility, or store approval.
Current store references:
[Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
and [Google Play](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).

## Privacy and screenshot creation

The validator processes files on the machine running the lane, makes no network
requests, uploads no screenshots, and sends no data to an AI model. On CI, that
machine is the CI runner; filenames and findings appear in its logs. Your other
Fastlane actions and CI provider have their own data handling.

[Screen Studio Kit](https://martingruner.com/projects/screenshot-studio) is an
optional app for creating screenshot sets. It is not required to run this check.
You can also use the [browser validator](https://martingruner.com/tools/store-screenshot-validator).

## Build and test

The runtime bundle is generated from the validator source under
`vendor/validate-store-screenshots` and the exact published
`@grunersoftware/store-screenshot-specs` 0.1.0 package. There is no
independently maintained rule table in this plugin.

```sh
npm --prefix vendor/validate-store-screenshots ci
node scripts/build.mjs
node --test test/validator.test.mjs
ruby test/action_test.rb
gem build fastlane-plugin-store_screenshot_check.gemspec
```

The Ruby integration test requires Fastlane to be installed. Rebuild the bundle
whenever the shared validator or specifications change. Keep `LICENSE` and
`THIRD_PARTY_LICENSES.txt` with the bundle.
