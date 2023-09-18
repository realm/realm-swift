#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

##########################
# Helpers
##########################

def remove_reference_to_realm_xcode_project(workspace_path)
  workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
  file_references = workspace.file_references.reject do |file_reference|
    file_reference.path == '../../../Realm.xcodeproj'
  end
  workspace = Xcodeproj::Workspace.new(nil)
  file_references.each { |ref| workspace << ref }
  workspace.save_as(workspace_path)
end

def replace_in_file(filepath, pattern, replacement)
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub(pattern, replacement)
  end
end

def replace_framework(example, framework, path)
  project_path = "#{example}/RealmExamples.xcodeproj"
  replace_in_file("#{project_path}/project.pbxproj",
                  /lastKnownFileType = wrapper.framework; path = (#{framework}).framework; sourceTree = BUILT_PRODUCTS_DIR;/,
                  "lastKnownFileType = wrapper.xcframework; name = \\1.xcframework; path = \"#{path}/\\1.xcframework\"; sourceTree = \"<group>\";")
  replace_in_file("#{project_path}/project.pbxproj",
                  /(#{framework}).framework/, "\\1.xcframework")
end

##########################
# Script
##########################

base_examples = [
  "examples/ios/objc",
  "examples/osx/objc",
  "examples/tvos/objc",
  "examples/ios/swift",
  "examples/tvos/swift",
]

xcode_versions = %w(14.1 14.2 14.3.1 15.0)

# Remove reference to Realm.xcodeproj from all example workspaces.
base_examples.each do |example|
  remove_reference_to_realm_xcode_project("#{example}/RealmExamples.xcworkspace")
end

# Make a copy of each Swift example for each Swift version.
base_examples.each do |example|
  if example =~ /\/swift$/
    xcode_versions.each do |xcode_version|
      FileUtils.cp_r example, "#{example}-#{xcode_version}"
    end
    FileUtils.rm_r example
  end
end

# Update the paths to the prebuilt frameworks
replace_framework('examples/ios/objc', 'Realm', '../../../static')
replace_framework('examples/osx/objc', 'Realm', '../../..')
replace_framework('examples/tvos/objc', 'Realm', '../../..')

xcode_versions.each do |xcode_version|
  replace_framework("examples/ios/swift-#{xcode_version}", 'Realm', "../../..")
  replace_framework("examples/tvos/swift-#{xcode_version}", 'Realm', "../../..")
  replace_framework("examples/ios/swift-#{xcode_version}", 'RealmSwift', "../../../#{xcode_version}")
  replace_framework("examples/tvos/swift-#{xcode_version}", 'RealmSwift', "../../../#{xcode_version}")
end

# Update Playground imports and instructions

xcode_versions.each do |xcode_version|
  playground_file = "examples/ios/swift-#{xcode_version}/GettingStarted.playground/Contents.swift"
  replace_in_file(playground_file, 'choose RealmSwift', 'choose PlaygroundFrameworkWrapper')
  replace_in_file(playground_file,
                  "import Foundation\n",
                  "import Foundation\nimport PlaygroundFrameworkWrapper // only necessary to use a binary release of Realm Swift in this playground.\n")
end

