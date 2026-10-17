require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'fastlane'
require_relative '../lib/fastlane/plugin/store_screenshot_check'

class StoreScreenshotCheckTest < Minitest::Test
  Action = Fastlane::Actions::StoreScreenshotCheckAction

  def setup
    @root = Dir.mktmpdir('fastlane-action-')
    @directory = 'screenshots with spaces; literal'
    FileUtils.mkdir_p(File.join(@root, @directory))
    fixture = File.expand_path('../vendor/validate-store-screenshots/fixtures/passing/screenshots/01.png', __dir__)
    FileUtils.cp(fixture, File.join(@root, @directory, '01.png'))
    @params = { directory: @directory, workspace: @root, target: 'apple-iphone-69' }
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def config(extra = {})
    FastlaneCore::Configuration.create(Action.available_options, @params.merge(extra))
  end

  def test_action_returns_report_using_real_fastlane_configuration
    report = Action.run(config)
    assert_equal 1, report['files']
    assert_equal 0, report['failures']
    assert_equal '0.1.0', report['specsVersion']
  end

  def test_failures_stop_the_lane_unless_explicitly_disabled
    File.write(File.join(@root, @directory, 'bad.png'), 'not an image')
    assert_raises(FastlaneCore::Interface::FastlaneError) { Action.run(config) }
    report = Action.run(config(fail_on_error: false))
    assert_equal 1, report['failures']
    assert_equal 1, report['errors'].size
  end

  def test_configuration_errors_and_missing_executable_always_fail
    assert_raises(FastlaneCore::Interface::FastlaneError) { Action.run(config(target: 'google-tablet', fail_on_error: false)) }
    assert_raises(FastlaneCore::Interface::FastlaneError) { Action.run(config(directory: '..', fail_on_error: false)) }
    assert_raises(FastlaneCore::Interface::FastlaneError) { Action.run(config(node: File.join(@root, 'missing-node'))) }
  end

  def test_real_fastlane_lane_stops_before_next_action
    runner = <<~RUBY
      require 'fastlane'
      require #{File.expand_path('../lib/fastlane/plugin/store_screenshot_check', __dir__).inspect}
      fastfile = Fastlane::FastFile.new
      fastfile.parse(#{<<~LANE.inspect})
        lane :verify do
          store_screenshot_check(workspace: #{@root.inspect}, directory: #{@directory.inspect}, target: 'apple-iphone-69')
          File.write(#{File.join(@root, 'after-check').inspect}, 'ran')
        end
      LANE
      fastfile.runner.execute(:verify)
    RUBY
    env = { 'FASTLANE_SKIP_UPDATE_CHECK' => '1', 'FASTLANE_OPT_OUT_USAGE' => '1', 'CI' => '1' }
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, '-e', runner)
    assert status.success?, stdout + stderr
    assert File.exist?(File.join(@root, 'after-check'))
    FileUtils.rm(File.join(@root, 'after-check'))
    File.write(File.join(@root, @directory, 'broken.png'), 'broken')
    _stdout, _stderr, status = Open3.capture3(env, RbConfig.ruby, '-e', runner)
    refute status.success?
    refute File.exist?(File.join(@root, 'after-check'))
  end
end
