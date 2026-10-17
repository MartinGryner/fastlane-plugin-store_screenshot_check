require 'fastlane/action'
require 'json'
require 'open3'

module Fastlane
  module Actions
    class StoreScreenshotCheckAction < Action
      def self.run(params)
        helper = File.expand_path('../helper/validate.cjs', __dir__)
        request = {
          directory: params[:directory], target: params[:target],
          workspace: File.expand_path(params[:workspace]),
          fail_on_error: params[:fail_on_error], fail_on_review: params[:fail_on_review]
        }
        # Separate arguments avoid interpreting directory names or executable paths as shell code.
        stdout, stderr, status = Open3.capture3(
          [params[:node], params[:node]], helper, stdin_data: JSON.generate(request)
        )
        begin
          report = JSON.parse(stdout)
        rescue JSON::ParserError
          UI.user_error!("Screenshot validator did not return JSON. #{stderr.strip}")
        end
        UI.user_error!(report['error'] || "Screenshot validator failed: #{stderr.strip}") unless [0, 1].include?(status.exitstatus)
        UI.message("Screenshot check: #{report['files']} files, #{report['failures']} failures, #{report['reviews']} review warnings (#{report['target']})")
        report.fetch('errors', []).each { |error| UI.error("#{error['name']}: #{error['message']}") }
        report.fetch('results', []).each do |result|
          result.fetch('checks').each do |check|
            next if check['tone'] == 'pass'
            message = "#{result['name']}: #{check['label']}: #{check['detail']}"
            check['tone'] == 'fail' ? UI.error(message) : UI.important(message)
          end
        end
        count = report.fetch('countCheck')
        UI.important(count['detail']) unless count['tone'] == 'pass'
        UI.user_error!('Screenshot validation failed. See the file and set diagnostics above.') unless status.success?
        report
      rescue Errno::ENOENT => error
        UI.user_error!("Unable to start screenshot validator. Install Node.js 22 or newer and set node to its executable if needed. #{error.message}")
      end

      def self.description
        'Validate one Apple or Google Play phone screenshot folder before upload'
      end

      def self.details
        'Uses bundled shared store-screenshot-specs rules and PNG/JPEG decoders. Requires Node.js 22+. Runs locally on the lane host. Does not upload files or guarantee store approval.'
      end

      def self.authors
        ['Martin Grüner']
      end

      def self.return_value
        'Hash with target, files, failures, reviews, passes, results, errors, countCheck and specsVersion (string keys)'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :directory, env_name: 'STORE_SCREENSHOT_CHECK_DIRECTORY', description: 'One non-recursive screenshot directory inside workspace', type: String),
          FastlaneCore::ConfigItem.new(key: :target, env_name: 'STORE_SCREENSHOT_CHECK_TARGET', description: 'Supported apple-* target ID or google-phone; see README', type: String),
          FastlaneCore::ConfigItem.new(key: :workspace, env_name: 'STORE_SCREENSHOT_CHECK_WORKSPACE', description: 'Root that screenshot directory must be inside', type: String, optional: true, default_value: Dir.pwd),
          FastlaneCore::ConfigItem.new(key: :node, env_name: 'STORE_SCREENSHOT_CHECK_NODE', description: 'Node.js 22+ executable name or path', type: String, optional: true, default_value: 'node'),
          FastlaneCore::ConfigItem.new(key: :fail_on_error, env_name: 'STORE_SCREENSHOT_CHECK_FAIL_ON_ERROR', description: 'Stop the lane for invalid screenshot files or set counts', type: Boolean, optional: true, default_value: true),
          FastlaneCore::ConfigItem.new(key: :fail_on_review, env_name: 'STORE_SCREENSHOT_CHECK_FAIL_ON_REVIEW', description: 'Also stop the lane for manual-review warnings', type: Boolean, optional: true, default_value: false)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end
