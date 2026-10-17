require_relative 'lib/fastlane/plugin/store_screenshot_check/version'

Gem::Specification.new do |spec|
  spec.name = 'fastlane-plugin-store_screenshot_check'
  spec.version = Fastlane::StoreScreenshotCheck::VERSION
  spec.author = 'Martin Grüner'
  spec.summary = 'Check Apple and Google Play phone screenshot folders before upload'
  spec.description = 'A Fastlane action using bundled shared screenshot rules and PNG/JPEG decoders. Requires Node.js 22 or newer on the lane host.'
  spec.homepage = 'https://github.com/MartinGryner/fastlane-plugin-store_screenshot_check'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'
  spec.files = Dir.chdir(__dir__) { Dir['lib/**/*', 'README.md', 'LICENSE', 'THIRD_PARTY_LICENSES.txt'] }.select { |path| File.file?(File.join(__dir__, path)) }
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'fastlane', '>= 2.220', '< 3'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = spec.homepage + '/issues'
end
