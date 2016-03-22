#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

##########################
# Helpers
##########################

def remove_reference_to_realm_xcode_project(workspace_path)
  old_workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
  file_references = old_workspace.file_references.reject do |file_reference|
    file_reference.path  == "../../../Realm.xcodeproj"
  end

  File.open("#{workspace_path}/contents.xcworkspacedata", "w") do |file|
    file.puts Xcodeproj::Workspace.new(file_references).to_s
  end
end

def set_framework_search_path(project_path, search_path)
  project = Xcodeproj::Project.open(project_path)
  project.build_configuration_list.set_setting("FRAMEWORK_SEARCH_PATHS", search_path)
  project.save
end

def replace_in_file(filepath, pattern, replacement)
  contents = File.read(filepath)
  File.open(filepath, "w") do |file|
    file.puts contents.gsub(pattern, replacement)
  end
end

##########################
# Script
##########################

# Create Xcode 6 and Xcode 7 versions of the iOS examples
FileUtils.mkdir 'examples/ios/xcode-6'
FileUtils.move 'examples/ios/objc', 'examples/ios/xcode-6'
FileUtils.move 'examples/ios/rubymotion', 'examples/ios/xcode-6'
FileUtils.cp_r 'examples/ios/xcode-6', 'examples/ios/xcode-7'

examples = [
  "examples/ios/xcode-6/objc",
  "examples/ios/xcode-7/objc",
  "examples/osx/objc",
  "examples/tvos/objc",
  "examples/ios/swift-2.2",
  "examples/tvos/swift",
]

# Remove reference to Realm.xcodeproj from all example workspaces.
examples.each do |example|
  remove_reference_to_realm_xcode_project("#{example}/RealmExamples.xcworkspace")
end

framework_directory_for_example = {
  'examples/ios/xcode-6/objc' => '../../../../ios/static/xcode-6',
  'examples/ios/xcode-7/objc' => '../../../../ios/static/xcode-7',
  'examples/osx/objc' => '../../../osx',
  'examples/tvos/objc' => '../../../tvos',
  'examples/ios/swift-2.2' => '../../../ios/swift-2.2',
  'examples/tvos/swift' => '../../../tvos',
}

# Update the paths to the prebuilt frameworks
examples.each do |example|
  project_path = "#{example}/RealmExamples.xcodeproj"
  framework_directory = framework_directory_for_example[example]

  replace_in_file("#{project_path}/project.pbxproj", /path = (Realm|RealmSwift).framework; sourceTree = BUILT_PRODUCTS_DIR;/, "path = \"#{framework_directory}/\\1.framework\"; sourceTree = SOURCE_ROOT;")
  set_framework_search_path(project_path, framework_directory)
end

# Update RubyMotion sample

replace_in_file('examples/ios/xcode-6/rubymotion/Simple/Rakefile', '/build/ios', '/ios/static/xcode-6')
replace_in_file('examples/ios/xcode-7/rubymotion/Simple/Rakefile', '/build/ios', '/ios/static/xcode-7')
