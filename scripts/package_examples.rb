#!/usr/bin/env ruby
require 'xcodeproj'

##########################
# Functions
##########################

def remove_subprojects_from_example(example)
  project = Xcodeproj::Project.open(example)

  project.targets.each do |target|
    target.build_phases.each do |build_phase|
      build_phase.files.each do |file|
        if file.display_name == "ReferenceProxy"
          build_phase.remove_build_file(file)
        end
      end
    end
  end

  project.objects.each do |object|
    if object.respond_to?(:name) && object.name != nil && object.name.include?(".xcodeproj")
      object.remove_from_project
    end
  end

  project.save
end

def add_framework(example, framework_path)
  project = Xcodeproj::Project.open(example)
  
  # Add file reference
  obj = project.new(Xcodeproj::Project::PBXFileReference)
  obj.path = framework_path
  obj.name = "Realm.framework"
  project.main_group << obj

  project.targets.each do |target|
    # Add to copy build phase
    target.resources_build_phase.add_file_reference(obj)

    # Add to frameworks build phase
    target.frameworks_build_phase.add_file_reference(obj)
  end

  project.save
end

##########################
# Script
##########################

# objc_examples = [
#   "examples/ios/objc/RealmExamples.xcodeproj",
#   "examples/osx/objc/RealmExamples.xcodeproj"
# ]

# objc_examples.each do |example|
#   remove_subprojects_from_example(example)

#   framework_search_paths_to_replace = "../../../build/${CONFIGURATION}"
#   filepath = File.join(example, "project.pbxproj")
#   contents = File.read(filepath)
#   if contents.include?(framework_search_paths_to_replace)
#     # static framework approach
#     File.open(filepath, "w") do |file|
#       file.puts contents.gsub(framework_search_paths_to_replace, "../../")
#     end
#   else
#     # dynamic framework approach
#     add_framework(example, "../../Realm.framework")
#   end
# end

# # Update RubyMotion sample

# rakefile_path = "examples/ios/rubymotion/Simple/Rakefile"
# contents = File.read(rakefile_path)
# File.open(rakefile_path, "w") do |file|
#   file.puts contents.gsub("../../../../", "../../../")
# end

swift_examples = [
  "examples/ios/swift/RealmExamples.xcodeproj"
]

swift_examples.each do |example|
  remove_subprojects_from_example(example)

  # dynamic framework approach
  add_framework(example, "Realm.framework")
end
